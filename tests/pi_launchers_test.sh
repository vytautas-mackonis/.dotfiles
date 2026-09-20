#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_HOME=$(mktemp -d)
STUB_BIN=$(mktemp -d)
LOG="$TEST_HOME/commands.log"
trap 'rm -rf "$TEST_HOME" "$STUB_BIN"' EXIT

cat >"$STUB_BIN/pi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'pi' >>"$COMMAND_LOG"; printf ' %q' "$@" >>"$COMMAND_LOG"; printf '\n' >>"$COMMAND_LOG"
EOF
cat >"$STUB_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'git' >>"$COMMAND_LOG"; printf ' %q' "$@" >>"$COMMAND_LOG"; printf '\n' >>"$COMMAND_LOG"
EOF
chmod +x "$STUB_BIN"/*

export HOME="$TEST_HOME"
export PATH="$STUB_BIN:$PATH"
export COMMAND_LOG="$LOG"
mkdir -p "$HOME/agent-skillsets/mattpocock-skills/skills" "$HOME/agent-skillsets/superpowers/.pi/extensions"

fish -c "source '$ROOT/shell/include.fish'; set -gx PATH '$STUB_BIN' \$PATH; pi prompt"
grep -Fq -- "pi --skill $HOME/agent-skillsets/mattpocock-skills/skills prompt" "$LOG"

: >"$LOG"
bash -c 'source "$1/shell/include.sh"; PATH="$2:$PATH"; pi prompt' _ "$ROOT" "$STUB_BIN"
grep -Fq -- "pi --skill $HOME/agent-skillsets/mattpocock-skills/skills prompt" "$LOG"

: >"$LOG"
zsh -c 'source "$1/shell/include.sh"; PATH="$2:$PATH"; pi prompt' _ "$ROOT" "$STUB_BIN"
grep -Fq -- "pi --skill $HOME/agent-skillsets/mattpocock-skills/skills prompt" "$LOG"

: >"$LOG"
fish -c "source '$ROOT/shell/include.fish'; set -gx PATH '$STUB_BIN' \$PATH; pi install npm:example"
grep -Fq -- "pi install npm:example" "$LOG"
! grep -Fq -- '--skill' "$LOG"

: >"$LOG"
bash "$ROOT/bin/pi-superpowers" prompt
superpowers_call=$(cat "$LOG")
grep -Fq -- "--skill $HOME/agent-skillsets/superpowers/skills" <<<"$superpowers_call"
grep -Fq -- "-e $HOME/agent-skillsets/superpowers/.pi/extensions/superpowers.ts" <<<"$superpowers_call"
! grep -Fq -- '--no-skills' <<<"$superpowers_call"
! grep -Fq -- 'mattpocock' <<<"$superpowers_call"

: >"$LOG"
bash "$ROOT/bin/pi-update"
grep -Fq -- 'pi update --all' "$LOG"
grep -Fq -- "git -C $HOME/agent-skillsets/mattpocock-skills pull --ff-only" "$LOG"
grep -Fq -- "git -C $HOME/agent-skillsets/superpowers pull --ff-only" "$LOG"

printf 'pi launcher test passed\n'
