#!/data/data/com.termux/files/usr/bin/bash
# scripts/launcher.sh — Pure Android launcher
# Runs OpenCode JS bundle via Android-native Bun.
# No glibc, no statx shim, no bun-termux-loader.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUN_RUNTIME="$SELF_DIR/../lib/opencode/runtime/bun"
BUNDLE_JS="$SELF_DIR/../lib/opencode/bundle.js"

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
	local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/opencode"
	if [ -d "$state_dir" ]; then
		find "$state_dir" -maxdepth 1 -type f -name '*.lock' -delete 2>/dev/null || true
	fi
}

trap 'cleanup_tty_full; exit 130' INT TERM HUP QUIT
cleanup_state_locks
: "${OPENCODE_DISABLE_DEFAULT_PLUGINS:=1}"
export OPENCODE_DISABLE_DEFAULT_PLUGINS

if [[ ! -x "$BUN_RUNTIME" ]]; then
	echo "opencode: Android Bun runtime not found" >&2
	exit 1
fi

if [[ -f "$BUNDLE_JS" ]]; then
	exec "$BUN_RUNTIME" run "$BUNDLE_JS" "$@"
else
	echo "opencode: JS bundle not found at $BUNDLE_JS" >&2
	echo "opencode: OpenCode AI features require the JS bundle" >&2
	exec "$BUN_RUNTIME" "$@"
fi
