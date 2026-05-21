#!/data/data/com.termux/files/usr/bin/bash
# tools/produce-local.sh — Pure Android: download Android native Bun only
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/artifacts/opencode/runtime"
BUN_OUT="$RUNTIME_DIR/bun"
BUN_ANDROID_VER="${BUN_ANDROID_VER:-1.3.14}"

log() { printf '[produce-pure] %s\n' "$*"; }
die() { printf '[produce-pure] ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }

ARCH="${ARCH:-aarch64}"
case "$ARCH" in
	aarch64|arm64) BUN_ARCH="aarch64" ;;
	x86_64|amd64)  BUN_ARCH="x64" ;;
	*) die "unsupported arch: $ARCH" ;;
esac

BUN_ZIP="bun-linux-${BUN_ARCH}-android.zip"
BUN_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_ANDROID_VER}/${BUN_ZIP}"

log "Android Bun v$BUN_ANDROID_VER for $BUN_ARCH"

WORK_BASE="${WORK_BASE:-$ROOT_DIR/.work}"
WORK_DIR="$WORK_BASE/bun-$BUN_ARCH-$BUN_ANDROID_VER"
rm -rf "$WORK_DIR" "$RUNTIME_DIR"
mkdir -p "$WORK_DIR" "$RUNTIME_DIR"

need curl
curl -fL "$BUN_URL" -o "$WORK_DIR/$BUN_ZIP" || die "download failed"
log "downloaded"

mkdir -p "$WORK_DIR/extracted"
unzip -o "$WORK_DIR/$BUN_ZIP" -d "$WORK_DIR/extracted" >/dev/null 2>&1 || die "unzip failed"
BUN_BIN="$(find "$WORK_DIR/extracted" -name 'bun' -type f | head -1)"
[[ -n "$BUN_BIN" && -x "$BUN_BIN" ]] || die "bun binary not found"
install -m 755 "$BUN_BIN" "$BUN_OUT"
log "installed: $(file "$BUN_OUT" | cut -d: -f2)"
log "version: $("$BUN_OUT" --version 2>/dev/null || echo 'unknown')"

rm -rf "$WORK_DIR"
rm -rf "$ROOT_DIR/artifacts/staged" "$ROOT_DIR/packaging/dpkg/work" "$ROOT_DIR/packaging/pacman/src"
log "DONE"
