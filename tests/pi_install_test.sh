#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_HOME=$(mktemp -d)
STUB_BIN=$(mktemp -d)
LOG="$TEST_HOME/commands.log"
trap 'rm -rf "$TEST_HOME" "$STUB_BIN"' EXIT

cat >"$STUB_BIN/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'npm %q\n' "$*" >>"$COMMAND_LOG"
EOF

cat >"$STUB_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'pi' >>"$COMMAND_LOG"; printf ' %q' "$@" >>"$COMMAND_LOG"; printf '\n' >>"$COMMAND_LOG"
EOF

cat >"$STUB_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'git' >>"$COMMAND_LOG"; printf ' %q' "$@" >>"$COMMAND_LOG"; printf '\n' >>"$COMMAND_LOG"
if [[ "${1:-}" == "-C" && "${3:-}" == "pull" && "${PI_TEST_NON_FF:-0}" == 1 ]]; then
  printf 'non-fast-forward\n' >&2
  exit 1
fi
if [[ "${1:-}" == "clone" ]]; then
  mkdir -p "$3/.git"
fi
EOF
chmod +x "$STUB_BIN"/*

export HOME="$TEST_HOME"
export PATH="$STUB_BIN:$PATH"
export COMMAND_LOG="$LOG"
export OS_FAMILY=linux OS_DISTRO=test OS_ENV=test OS_NAME=test

mkdir -p "$HOME/.pi/agent"
printf '{"lastChangelogVersion":"0.86.1","theme":"light"}\n' >"$HOME/.pi/agent/settings.json"
printf 'credential\n' >"$HOME/.pi/agent/auth.json"
printf 'catalog\n' >"$HOME/.pi/agent/models-store.json"
cp "$HOME/.pi/agent/auth.json" "$HOME/auth.expected"
cp "$HOME/.pi/agent/models-store.json" "$HOME/models.expected"

bash "$ROOT/scripts/pi/install.sh"

settings="$HOME/.pi/agent/settings.json"
[[ ! -L "$settings" ]]
node - "$settings" "$ROOT/pi/settings.json" <<'NODE'
const fs = require("fs");
const settings = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const template = JSON.parse(fs.readFileSync(process.argv[3], "utf8"));
if (settings.lastChangelogVersion !== "0.86.1") process.exit(1);
if (settings.theme !== template.theme) process.exit(1);
if (settings.defaultModel !== template.defaultModel) process.exit(1);
NODE
cmp "$HOME/.pi/agent/auth.json" "$HOME/auth.expected"
cmp "$HOME/.pi/agent/models-store.json" "$HOME/models.expected"
grep -Fq 'pi install npm:pi-subagents' "$LOG"
grep -Fq 'pi install npm:@gotgenes/pi-anthropic-auth' "$LOG"
grep -Fq "git clone https://github.com/mattpocock/skills $HOME/agent-skillsets/mattpocock-skills" "$LOG"
grep -Fq "git clone https://github.com/obra/superpowers $HOME/agent-skillsets/superpowers" "$LOG"

: >"$LOG"
bash "$ROOT/scripts/pi/install.sh"
grep -Fq "git -C $HOME/agent-skillsets/mattpocock-skills pull --ff-only" "$LOG"
grep -Fq "git -C $HOME/agent-skillsets/superpowers pull --ff-only" "$LOG"

printf 'unchanged\n' >"$HOME/agent-skillsets/mattpocock-skills/marker"
export PI_TEST_NON_FF=1
if bash "$ROOT/scripts/pi/install.sh" >/dev/null 2>&1; then
  printf 'expected non-fast-forward failure\n' >&2
  exit 1
fi
[[ "$(<"$HOME/agent-skillsets/mattpocock-skills/marker")" == unchanged ]]

printf 'pi installer test passed\n'
