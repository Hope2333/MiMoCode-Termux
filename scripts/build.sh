#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common.sh"

MIMOCODE_SRC_DIR="${MIMOCODE_SRC_DIR:-$ROOT_DIR/sources/mimocode/repo}"
OUT_DIR="${MIMOCODE_OUT_DIR:-$ROOT_DIR/artifacts/staged}"
PREFIX_DIR="${MIMOCODE_PREFIX_DIR:-$OUT_DIR/prefix}"
RUNTIME_INPUT="${MIMOCODE_RUNTIME_INPUT:-$ROOT_DIR/artifacts/mimocode/runtime/mimocode-termux}"

ensure_dir "$PREFIX_DIR/lib/mimocode/runtime"
ensure_dir "$PREFIX_DIR/bin"
ensure_dir "$PREFIX_DIR/lib/mimocode/tools"
ensure_dir "$PREFIX_DIR/lib/mimocode/system-skills"

if [[ -d "$MIMOCODE_SRC_DIR" ]]; then
	log "copying source from $MIMOCODE_SRC_DIR"
	if command -v rsync >/dev/null 2>&1; then
		rsync -a --delete --exclude '.git' --exclude 'node_modules' "$MIMOCODE_SRC_DIR/" "$PREFIX_DIR/lib/mimocode/"
	else
		rm -rf "$PREFIX_DIR/lib/mimocode"
		ensure_dir "$PREFIX_DIR/lib/mimocode"
		cp -a "$MIMOCODE_SRC_DIR/." "$PREFIX_DIR/lib/mimocode/"
		rm -rf "$PREFIX_DIR/lib/mimocode/.git" "$PREFIX_DIR/lib/mimocode/node_modules"
	fi
else
	log "source tree not found; continuing runtime-only staging"
fi

# Install wrapped MiMoCode runtime
if [[ -f "$RUNTIME_INPUT" ]]; then
	install -m 755 "$RUNTIME_INPUT" "$PREFIX_DIR/lib/mimocode/runtime/mimocode"
	log "installed MiMoCode runtime binary"
	RUNTIME_MODE="mimocode-wrapped"
else
	fail "no runtime found at $RUNTIME_INPUT"
fi

# Optional: JS bundle (built on CI, run via Android Bun)
BUNDLE_INPUT="${MIMOCODE_BUNDLE_INPUT:-$ROOT_DIR/artifacts/mimocode/runtime/bundle.js}"
if [[ -f "$BUNDLE_INPUT" ]]; then
	install -m 644 "$BUNDLE_INPUT" "$PREFIX_DIR/lib/mimocode/bundle.js"
	log "installed JS bundle"
fi

install -m 755 "$ROOT_DIR/scripts/launcher.sh" "$PREFIX_DIR/bin/mimo"
if [[ -f "$ROOT_DIR/tools/plugin-manager.sh" ]]; then
	install -m 755 "$ROOT_DIR/tools/plugin-manager.sh" "$PREFIX_DIR/lib/mimocode/tools/plugin-manager.sh"
fi
if [[ -f "$ROOT_DIR/tools/plugin-selfcheck.sh" ]]; then
	install -m 755 "$ROOT_DIR/tools/plugin-selfcheck.sh" "$PREFIX_DIR/lib/mimocode/tools/plugin-selfcheck.sh"
fi
if [[ -f "$ROOT_DIR/scripts/hooks/run-system-skills.sh" ]]; then
	install -m 755 "$ROOT_DIR/scripts/hooks/run-system-skills.sh" "$PREFIX_DIR/lib/mimocode/tools/run-system-skills.sh"
fi
if [[ -d "$ROOT_DIR/packaging/manifests/system-skills" ]]; then
	cp -a "$ROOT_DIR/packaging/manifests/system-skills/." "$PREFIX_DIR/lib/mimocode/system-skills/"
fi

DOCS_LIST="${DOCS_LIST:-$ROOT_DIR/docs/bundle-list.txt}"
DOCS_OUT="$PREFIX_DIR/share/mimocode/docs"
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
write_build_meta "$ROOT_DIR/artifacts/mimocode/build.meta" \
	"component=mimocode" \
	"prefix=$PREFIX_DIR" \
	"runtime_mode=android-only" \
	"runtime_path=$PREFIX_DIR/lib/mimocode/runtime/mimocode"

log "staged build ready: $PREFIX_DIR"
