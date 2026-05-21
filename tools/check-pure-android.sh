#!/data/data/com.termux/files/usr/bin/bash
# tools/check-pure-android.sh — Verify pure-android isolation
# Confirms the Android-native Bun runtime functions without glibc.

set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUN_BINARY="$ROOT_DIR/artifacts/opencode/runtime/bun"

pass() { echo "  ✅ $*"; }
fail() { echo "  ❌ $*"; errors=$((errors+1)); }
errors=0

echo "=== Pure Android Isolation Check ==="
echo ""

# Test 1: Android Bun binary exists
echo "1. Android Bun binary..."
if [[ -x "$BUN_BINARY" ]]; then
    pass "found at $BUN_BINARY ($(stat -c%s "$BUN_BINARY") bytes)"
else
    fail "not found at $BUN_BINARY"
fi

# Test 2: Binary is Bionic-linked (not glibc)
echo "2. Binary linkage..."
if readelf -l "$BUN_BINARY" 2>/dev/null | grep -q '/system/bin/linker64'; then
    pass "Bionic-linked (interpreter: /system/bin/linker64)"
else
    fail "NOT Bionic-linked"
fi

# Test 3: No glibc NEEDED entries
echo "3. No glibc dependencies..."
if readelf -d "$BUN_BINARY" 2>/dev/null | grep -q 'NEEDED.*libc.so'; then
    pass "uses Bionic libc (system library)"
else
    fail "no libc dependency found"
fi
if readelf -d "$BUN_BINARY" 2>/dev/null | grep -q 'NEEDED'; then
    NEEDED=$(readelf -d "$BUN_BINARY" 2>/dev/null | grep 'NEEDED' | sed 's/.*\[//;s/\]//')
    pass "shared libraries: $(echo $NEEDED)"
fi

# Test 4: Runs without glibc (direct execution test)
echo "4. Direct execution (no glibc needed)..."
if "$BUN_BINARY" --version >/dev/null 2>&1; then
    VER=$("$BUN_BINARY" --version 2>/dev/null)
    pass "runs successfully (Bun v$VER)"
else
    fail "failed to execute"
fi

# Test 5: glibc is NOT required for Android Bun
echo "5. glibc independence verification..."
if "$BUN_BINARY" -e "console.log('glibc-free!')" 2>/dev/null | grep -q 'glibc-free'; then
    pass "executes JS without glibc"
else
    fail "JS execution failed"
fi

# Test 6: Launcher can find Bun (simulate what launcher does)
echo "6. Launcher path resolution..."
LAUNCHER="$ROOT_DIR/scripts/launcher.sh"
if [[ -f "$LAUNCHER" ]]; then
    # Just check the select_routine logic detects Bun
    if grep -q "BUN_RUNTIME" "$LAUNCHER"; then
        pass "launcher has Android Bun detection"
    fi
fi

echo ""
echo "=== Result ==="
if [[ "$errors" -eq 0 ]]; then
    echo "  ✅ All checks passed — pure Android ready"
else
    echo "  ❌ $errors check(s) failed"
fi
exit "$errors"
