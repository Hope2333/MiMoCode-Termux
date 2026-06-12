#!/data/data/com.termux/files/usr/bin/bash
# tools/produce-local.sh — Build MiMoCode for Termux
# Downloads mimocode-linux-arm64 from GitHub releases + wraps with bun-termux-loader
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/artifacts/mimocode/runtime"
MIMOCODE_OUT="$RUNTIME_DIR/mimocode-termux"
INPUT_VER="${1:-}"
MIMOCODE_REPO="XiaomiMiMo/MiMo-Code"

log() { printf '[produce] %s\n' "$*"; }
die() { printf '[produce] ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }

# Default to latest release tag if no version specified
if [[ -z "$INPUT_VER" ]]; then
	INPUT_VER="$(gh release list --repo "$MIMOCODE_REPO" --limit 1 --json tagName --jq '.[0].tagName' 2>/dev/null | sed 's/^v//' || true)"
fi
[[ -n "$INPUT_VER" ]] || die "no version specified and cannot detect latest"
VER="$INPUT_VER"

CACHE_DIR="${CACHE_DIR:-$HOME/.cache/mimocode-termux}"
LOADER_DIR="/data/data/com.termux/files/home/bun-termux-loader"
EXTRACT="${TMPDIR:-$PREFIX/tmp}/produce-$$"
mkdir -p "$RUNTIME_DIR" "$CACHE_DIR" "$EXTRACT"
trap 'rm -rf $EXTRACT' EXIT

log "mimocode v$VER"

# Check cache
CACHE_BIN="$CACHE_DIR/mimocode-$VER"
if [[ -f "$CACHE_BIN" ]]; then
	log "cache hit"
	install -m 755 "$CACHE_BIN" "$MIMOCODE_OUT"
	"$MIMOCODE_OUT" --version 2>/dev/null || true
	rm -rf "$ROOT_DIR/artifacts/staged" "$ROOT_DIR/packaging/dpkg/work" "$ROOT_DIR/packaging/pacman/src"
	log "DONE"
	exit 0
fi

# Download from GitHub releases
need curl
cd "$EXTRACT"
TGZ="mimocode-linux-arm64.tar.gz"
URL="https://github.com/$MIMOCODE_REPO/releases/download/v${VER}/${TGZ}"
log "downloading $TGZ from GitHub releases (v$VER)"
curl -fL "$URL" -o "$TGZ" 2>&1 || die "download failed: $URL"
tar -xzf "$TGZ" 2>/dev/null
RAW="./mimocode"
if [[ ! -f "$RAW" ]]; then
	# Try searching in subdirectories
	RAW="$(find . -name "mimocode" -type f 2>/dev/null | head -1)" || true
fi
[[ -f "$RAW" && -x "$RAW" ]] || { chmod +x "$RAW" 2>/dev/null; [[ -x "$RAW" ]] || die "mimocode binary not found in tarball"; }

log "raw binary: $(file "$RAW" | cut -d: -f2)"

# Wrap with bun-termux-loader
if [[ ! -f "$LOADER_DIR/build.py" ]]; then
	log "cloning bun-termux-loader"
	git clone --depth 1 https://github.com/Hope2333/bun-termux-loader "$EXTRACT/loader" 2>/dev/null || die "clone failed"
	LOADER_DIR="$EXTRACT/loader"
fi

log "wrapping for Termux"
python3 "$LOADER_DIR/build.py" "$RAW" --wrapper "$LOADER_DIR/wrapper" --shim "$LOADER_DIR/bunfs_shim.so" 2>&1 | tail -3
WRAPPED="${RAW}-termux"
[[ -f "$WRAPPED" ]] || die "wrapping failed"

install -m 755 "$WRAPPED" "$MIMOCODE_OUT"
install -m 755 "$WRAPPED" "$CACHE_BIN"
log "done: $(file "$MIMOCODE_OUT" | cut -d: -f2)"
log "version: $("$MIMOCODE_OUT" --version 2>/dev/null || echo '?')"

rm -rf "$ROOT_DIR/artifacts/staged" "$ROOT_DIR/packaging/dpkg/work" "$ROOT_DIR/packaging/pacman/src"
log "DONE"
