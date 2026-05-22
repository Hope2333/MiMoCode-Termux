#!/data/data/com.termux/files/usr/bin/bash
# tools/produce-local.sh — Pure Android: download Android native Bun only
# With local caching to avoid re-downloading on batch builds.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
RUNTIME_DIR="$ROOT_DIR/artifacts/opencode/runtime"
BUN_OUT="$RUNTIME_DIR/bun"
BUN_ANDROID_VER="${BUN_ANDROID_VER:-1.3.14}"

log() { printf '[produce-pure] %s\n' "$*"; }
die() { printf '[produce-pure] ERROR: %s\n' "$*" >&2; exit 1; }

ARCH="${ARCH:-aarch64}"
case "$ARCH" in
	aarch64|arm64) BUN_ARCH="aarch64" ;;
	x86_64|amd64)  BUN_ARCH="x64" ;;
	*) die "unsupported arch: $ARCH" ;;
esac

BUN_ZIP="bun-linux-${BUN_ARCH}-android.zip"
BUN_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_ANDROID_VER}/${BUN_ZIP}"

# Cache under home directory (survives .work cleanup across batch iterations)
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/opencode-termux/bun-android}"
CACHE_ZIP="$CACHE_DIR/$BUN_ZIP"
CACHE_BIN="$CACHE_DIR/bun-$BUN_ARCH-$BUN_ANDROID_VER"

log "Android Bun v$BUN_ANDROID_VER for $BUN_ARCH"

# Clean runtime dir (but preserve cache)
rm -rf "$RUNTIME_DIR"
mkdir -p "$RUNTIME_DIR" "$CACHE_DIR"

# Extract directory (use TMPDIR or PREFIX/tmp, NOT /tmp which is unwritable on Termux)
EXTRACT_DIR="${TMPDIR:-$PREFIX/tmp}/bun-extract-$$"

if [[ -f "$CACHE_BIN" && -x "$CACHE_BIN" ]]; then
	# Cache hit: use cached binary directly
	log "cache hit: $CACHE_BIN"
	install -m 755 "$CACHE_BIN" "$BUN_OUT"
elif [[ -f "$CACHE_ZIP" ]]; then
	# Cache hit (zip): extract from cached zip
	log "cache hit (zip): $CACHE_ZIP"
	mkdir -p ${EXTRACT_DIR}
	unzip -o "$CACHE_ZIP" -d ${EXTRACT_DIR} >/dev/null 2>&1
	BUN_BIN="$(find ${EXTRACT_DIR} -name 'bun' -type f | head -1)"
	if [[ -n "$BUN_BIN" && -x "$BUN_BIN" ]]; then
		install -m 755 "$BUN_BIN" "$CACHE_BIN"
		install -m 755 "$BUN_BIN" "$BUN_OUT"
	fi
	rm -rf ${EXTRACT_DIR}
else
	# Cache miss: download
	log "downloading from $BUN_URL"
	need curl
	curl -fL "$BUN_URL" -o "$CACHE_ZIP" || die "download failed (try: https_proxy=http://127.0.0.1:7890)"
	log "downloaded to cache: $CACHE_ZIP"
	mkdir -p ${EXTRACT_DIR}
	unzip -o "$CACHE_ZIP" -d ${EXTRACT_DIR} >/dev/null 2>&1 || die "unzip failed"
	BUN_BIN="$(find ${EXTRACT_DIR} -name 'bun' -type f | head -1)"
	[[ -n "$BUN_BIN" && -x "$BUN_BIN" ]] || die "bun binary not found in zip"
	install -m 755 "$BUN_BIN" "$CACHE_BIN"
	install -m 755 "$BUN_BIN" "$BUN_OUT"
	rm -rf ${EXTRACT_DIR}
fi

log "installed: $(file "$BUN_OUT" | cut -d: -f2)"
log "version: $("$BUN_OUT" --version 2>/dev/null || echo 'unknown')"

# Clean build artifacts (not cache)
rm -rf "$ROOT_DIR/artifacts/staged" "$ROOT_DIR/packaging/dpkg/work" "$ROOT_DIR/packaging/pacman/src"
log "DONE"
