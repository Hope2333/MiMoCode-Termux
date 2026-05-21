#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

OPENCODE_SRC_DIR="${OPENCODE_SRC_DIR:-$ROOT_DIR/sources/opencode/repo}"
OUT_DIR="${OPENCODE_OUT_DIR:-$ROOT_DIR/artifacts/staged}"
PREFIX_DIR="${OPENCODE_PREFIX_DIR:-$OUT_DIR/prefix}"
RUNTIME_INPUT="${OPENCODE_RUNTIME_INPUT:-$ROOT_DIR/artifacts/opencode/runtime/opencode}"
BUN_ANDROID_INPUT="${OPENCODE_BUN_ANDROID_INPUT:-$ROOT_DIR/artifacts/opencode/runtime/bun}"

ensure_dir "$PREFIX_DIR/lib/opencode/runtime"
ensure_dir "$PREFIX_DIR/bin"
ensure_dir "$PREFIX_DIR/lib/opencode/tools"
ensure_dir "$PREFIX_DIR/lib/opencode/system-skills"

if [[ -d "$OPENCODE_SRC_DIR" ]]; then
	log "copying source from $OPENCODE_SRC_DIR"
	if command -v rsync >/dev/null 2>&1; then
		rsync -a --delete --exclude '.git' --exclude 'node_modules' "$OPENCODE_SRC_DIR/" "$PREFIX_DIR/lib/opencode/"
	else
		rm -rf "$PREFIX_DIR/lib/opencode"
		ensure_dir "$PREFIX_DIR/lib/opencode"
		cp -a "$OPENCODE_SRC_DIR/." "$PREFIX_DIR/lib/opencode/"
		rm -rf "$PREFIX_DIR/lib/opencode/.git" "$PREFIX_DIR/lib/opencode/node_modules"
	fi
else
	log "source tree not found; continuing runtime-only staging"
fi

if [[ -f "$RUNTIME_INPUT" ]]; then
	install -m 755 "$RUNTIME_INPUT" "$PREFIX_DIR/lib/opencode/runtime/opencode"
	RUNTIME_MODE="raw-linux"
elif [[ -f "$BUN_ANDROID_INPUT" ]]; then
	RUNTIME_MODE="android-only"
else
	fail "no runtime found (need opencode or bun android binary)"
fi

# Install Android-native Bun runtime (primary runtime for launcher)
if [[ -f "$BUN_ANDROID_INPUT" ]]; then
	install -m 755 "$BUN_ANDROID_INPUT" "$PREFIX_DIR/lib/opencode/runtime/bun"
	log "installed Android-native Bun (primary runtime)"
fi

install -m 755 "$ROOT_DIR/scripts/launcher.sh" "$PREFIX_DIR/bin/opencode"
if [[ -f "$ROOT_DIR/tools/plugin-manager.sh" ]]; then
	install -m 755 "$ROOT_DIR/tools/plugin-manager.sh" "$PREFIX_DIR/lib/opencode/tools/plugin-manager.sh"
fi
if [[ -f "$ROOT_DIR/tools/plugin-selfcheck.sh" ]]; then
	install -m 755 "$ROOT_DIR/tools/plugin-selfcheck.sh" "$PREFIX_DIR/lib/opencode/tools/plugin-selfcheck.sh"
fi
if [[ -f "$ROOT_DIR/scripts/hooks/run-system-skills.sh" ]]; then
	install -m 755 "$ROOT_DIR/scripts/hooks/run-system-skills.sh" "$PREFIX_DIR/lib/opencode/tools/run-system-skills.sh"
fi
if [[ -d "$ROOT_DIR/packaging/manifests/system-skills" ]]; then
	cp -a "$ROOT_DIR/packaging/manifests/system-skills/." "$PREFIX_DIR/lib/opencode/system-skills/"
fi

DOCS_LIST="${DOCS_LIST:-$ROOT_DIR/docs/bundle-list.txt}"
DOCS_OUT="$PREFIX_DIR/share/opencode/docs"
if [[ -f "$DOCS_LIST" ]]; then
	ensure_dir "$DOCS_OUT"
	while IFS= read -r rel; do
		[[ -z "$rel" ]] && continue
		[[ "$rel" == \#* ]] && continue
		src="$ROOT_DIR/$rel"
		if [[ -f "$src" ]]; then
			dest="$DOCS_OUT/${rel#docs/}"
			ensure_dir "$(dirname "$dest")"
			cp -a "$src" "$dest"
		else
			log "docs bundle missing: $rel"
		fi
	done <"$DOCS_LIST"
fi

# Compile statx-seccomp shim for Android/Termux compatibility
# statx shim: only needed for glibc-wrapped binary fallback
STATX_SHIM_SRC="$ROOT_DIR/tools/statx-shim.c"
STATX_SHIM_DST="$PREFIX_DIR/lib/opencode/lib/libstatx-shim.so"
if [[ -f "$STATX_SHIM_SRC" && "$RUNTIME_MODE" = "raw-linux" ]]; then
	log "compiling statx seccomp shim (for glibc fallback)"
	ensure_dir "$PREFIX_DIR/lib/opencode/lib"
	if command -v gcc >/dev/null 2>&1; then
		gcc -shared -fPIC -o "$STATX_SHIM_DST" "$STATX_SHIM_SRC" || log "warning: shim build failed"
	elif command -v cc >/dev/null 2>&1; then
		cc -shared -fPIC -o "$STATX_SHIM_DST" "$STATX_SHIM_SRC" || log "warning: shim build failed"
	fi
fi

write_build_meta "$ROOT_DIR/artifacts/opencode/build.meta" \
	"component=opencode" \
	"prefix=$PREFIX_DIR" \
	"runtime_mode=$RUNTIME_MODE" \
	"runtime_path=$PREFIX_DIR/lib/opencode/runtime/opencode"

log "staged build ready: $PREFIX_DIR"
