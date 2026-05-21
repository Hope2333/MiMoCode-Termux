#!/data/data/com.termux/files/usr/bin/bash
# tools/produce-local.sh — pure Android runtime preparation
# Downloads opencode-linux-arm64 + Android native Bun.
# No bun-termux-loader, no glibc wrapping.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_VER="${1:-}"

log() { printf '[produce-pure] %s\n' "$*"; }
die() { printf '[produce-pure] ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }

BUN_ANDROID_VER="${BUN_ANDROID_VER:-1.3.14}"

resolve_version() {
    if [[ -n "$INPUT_VER" ]]; then
        printf '%s' "$INPUT_VER"
        return 0
    fi
    local latest
    latest="$(npm view opencode-linux-arm64 version 2>/dev/null || true)"
    [[ -n "$latest" ]] || die "unable to resolve version"
    printf '%s' "$latest"
}

VER="$(resolve_version)"
WORK_BASE="${WORK_BASE:-$ROOT_DIR/.work}"
WORK_DIR="$WORK_BASE/pure-$VER"
RUNTIME_DIR="$ROOT_DIR/artifacts/opencode/runtime"
RUNTIME_OUT="$RUNTIME_DIR/opencode"
BUN_ANDROID_OUT="$RUNTIME_DIR/bun"

rm -rf "$WORK_DIR" "$RUNTIME_DIR"
mkdir -p "$WORK_DIR" "$RUNTIME_DIR"

log "version=$VER"
log "work_dir=$WORK_DIR"

# Step 1: Download opencode-linux-arm64 from npm
need npm
log "downloading opencode-linux-arm64@$VER from npm"
cd "$WORK_DIR"
npm pack "opencode-linux-arm64@$VER" >/dev/null 2>&1 || die "npm pack failed"
tgz="$(ls *.tgz | head -1)"
tar -xzf "$tgz"
[[ -x package/bin/opencode ]] || die "binary not found"
install -m 755 package/bin/opencode "$RUNTIME_OUT"
log "installed opencode binary: $(file "$RUNTIME_OUT" | cut -d: -f2)"

# Step 2: Download Android native Bun
log "downloading Android Bun v$BUN_ANDROID_VER"
ANDROID_ZIP="bun-linux-aarch64-android.zip"
ANDROID_URL="https://github.com/oven-sh/bun/releases/download/bun-v${BUN_ANDROID_VER}/${ANDROID_ZIP}"
if command -v curl >/dev/null 2>&1; then
    curl -fL "$ANDROID_URL" -o "$WORK_DIR/$ANDROID_ZIP" || die "download failed"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$WORK_DIR/$ANDROID_ZIP" "$ANDROID_URL" || die "download failed"
else
    die "need curl or wget"
fi
mkdir -p "$WORK_DIR/bun-android"
unzip -o "$WORK_DIR/$ANDROID_ZIP" -d "$WORK_DIR/bun-android" >/dev/null 2>&1
BUN_BIN="$(find "$WORK_DIR/bun-android" -name 'bun' -type f | head -1)"
[[ -n "$BUN_BIN" && -x "$BUN_BIN" ]] || die "Android Bun binary not found"
install -m 755 "$BUN_BIN" "$BUN_ANDROID_OUT"
log "installed Android Bun: $(file "$BUN_ANDROID_OUT" | cut -d: -f2)"

# Step 3: Verify
log "verifying..."
"$BUN_ANDROID_OUT" --version 2>&1 | xargs echo "  Android Bun version:"
# opencode binary might not run directly (glibc dep), but we bundle it
file "$RUNTIME_OUT" | xargs echo "  opencode binary:"

# Step 4: Clean
log "cleaning work directory"
rm -rf "$WORK_DIR"
rm -rf "$ROOT_DIR/artifacts/staged" "$ROOT_DIR/packaging/dpkg/work" "$ROOT_DIR/packaging/pacman/src"

log "DONE"
log "  opencode: $RUNTIME_OUT  (fallback, needs glibc)"
log "  bun:      $BUN_ANDROID_OUT  (primary, Android native)"
log ""
log "The launcher prefers Android Bun when both are installed."
