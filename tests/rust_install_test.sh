#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TEST_HOME=$(mktemp -d)
STUB_BIN=$(mktemp -d)
LOG="$TEST_HOME/commands.log"
trap 'rm -rf "$TEST_HOME" "$STUB_BIN"' EXIT

cat >"$STUB_BIN/rustup" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'rustup' >>"$COMMAND_LOG"; printf ' %q' "$@" >>"$COMMAND_LOG"; printf '\n' >>"$COMMAND_LOG"
EOF
cat >"$STUB_BIN/cargo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'cargo --version\n' >>"$COMMAND_LOG"
EOF
cat >"$STUB_BIN/rustc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'rustc --version\n' >>"$COMMAND_LOG"
EOF
chmod +x "$STUB_BIN"/*

export HOME="$TEST_HOME"
export PATH="$STUB_BIN:$PATH"
export COMMAND_LOG="$LOG"
export OS_FAMILY=linux OS_DISTRO=test OS_ENV=test OS_NAME=test

bash "$ROOT/scripts/rust/install.sh"
grep -Fq 'rustup toolchain install stable --profile default' "$LOG"
grep -Fq 'rustup default stable' "$LOG"
grep -Fq 'cargo --version' "$LOG"
grep -Fq 'rustc --version' "$LOG"
! grep -Fq -- '--no-modify-path' "$ROOT/scripts/rust/install.sh"

printf 'rust installer test passed\n'
