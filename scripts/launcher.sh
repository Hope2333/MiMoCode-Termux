#!/data/data/com.termux/files/usr/bin/bash
# scripts/launcher.sh — Pure Android launcher
# Runs Android-native Bun as the opencode command.
# No glibc, no statx shim, no bun-termux-loader.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUN_RUNTIME="$SELF_DIR/../lib/opencode/runtime/bun"

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

cleanup_broken_cached_modules() {
	local cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/opencode"
	local mod_dir="$cache_root/node_modules/opencode-anthropic-auth"
	if [ -d "$mod_dir" ] && [ ! -f "$mod_dir/package.json" ]; then
		rm -rf "$cache_root/node_modules" 2>/dev/null || true
	fi
}

trap 'cleanup_tty_full; exit 130' INT TERM HUP QUIT
cleanup_state_locks
cleanup_broken_cached_modules
: "${OPENCODE_DISABLE_DEFAULT_PLUGINS:=1}"
export OPENCODE_DISABLE_DEFAULT_PLUGINS

if [[ ! -x "$BUN_RUNTIME" ]]; then
	echo "opencode: Android Bun runtime not found at $BUN_RUNTIME" >&2
	echo "opencode: reinstall the package" >&2
	exit 1
fi

"$BUN_RUNTIME" "$@"
rc=$?
if [ "$rc" -eq 0 ]; then
	cleanup_tty_soft
else
	cleanup_tty_full
fi
exit $rc
