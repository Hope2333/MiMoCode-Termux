#!/data/data/com.termux/files/usr/bin/bash
# scripts/launcher.sh — MiMoCode launcher for Termux
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIMOCODE_RUNTIME="$SELF_DIR/../lib/mimocode/runtime/opencode"

cleanup_tty_full() {
	if [ -t 1 ]; then
		printf '\033[?1049l\033[?25h\033[0m' >/dev/tty 2>/dev/null || true
	fi
	command -v stty >/dev/null 2>&1 && stty sane 2>/dev/null || true
	command -v tput >/dev/null 2>&1 && tput rmcup >/dev/null 2>&1 || true
}

cleanup_tty_soft() {
	command -v stty >/dev/null 2>&1 && stty sane 2>/dev/null || true
	if [ -t 1 ]; then
		printf '\033[?25h\033[0m' >/dev/tty 2>/dev/null || true
	fi
}

cleanup_state_locks() {
	local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/mimocode"
	if [ -d "$state_dir" ]; then
		find "$state_dir" -maxdepth 1 -type f -name '*.lock' -delete 2>/dev/null || true
	fi
}

trap 'cleanup_tty_full; exit 130' INT TERM HUP QUIT
cleanup_state_locks
: "${MIMOCODE_DISABLE_DEFAULT_PLUGINS:=1}"
export MIMOCODE_DISABLE_DEFAULT_PLUGINS

if [[ ! -x "$MIMOCODE_RUNTIME" ]]; then
	echo "mimocode: runtime not found" >&2
	exit 1
fi

"$MIMOCODE_RUNTIME" "$@"
rc=$?
if [ "$rc" -eq 0 ]; then
	cleanup_tty_soft
else
	cleanup_tty_full
fi
exit $rc
