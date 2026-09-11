#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
TRANSPLANT_ROOT="${TRANSPLANT_ROOT:-$ROOT_DIR/artifacts/transplant}"
MAINTAINER="${MAINTAINER:-Hope2333(幽零小喵) <u0catmiao@proton.me>}"
ARCH_DEB="${ARCH_DEB:-$(dpkg --print-architecture 2>/dev/null || echo aarch64)}"

command -v dpkg-deb >/dev/null 2>&1 || {
	echo "Error: dpkg-deb not found"
	exit 1
}

# Version: use explicit VERSION if set, else auto-resolve from the single
# transplant build directory under artifacts/transplant/
if [[ -z "${VERSION:-}" ]]; then
	mapfile -t BUILDS < <(find "$TRANSPLANT_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
	if [[ ${#BUILDS[@]} -eq 0 ]]; then
		echo "Error: no transplant builds under $TRANSPLANT_ROOT (set VERSION explicitly?)"
		exit 1
	fi
	if [[ ${#BUILDS[@]} -gt 1 ]]; then
		echo "Error: multiple transplant builds found, set VERSION explicitly:"
		printf '  %s\n' "${BUILDS[@]##*/}"
		exit 1
	fi
	VERSION="${BUILDS[0]##*/}"
fi

NATIVE_BIN="$TRANSPLANT_ROOT/$VERSION/mimocode-native-revived-tui"
# Fallback: -tui variant absent (TUI slot-size swap infeasible for 0.1.13) -> plain revived
[[ -x "$NATIVE_BIN" ]] || NATIVE_BIN="$TRANSPLANT_ROOT/$VERSION/mimocode-native-revived"
[[ -x "$NATIVE_BIN" ]] || {
	echo "Error: native binary not found or not executable: $NATIVE_BIN"
	exit 1
}

DEB_ROOT="$ROOT_DIR/packing/dpkg/work-native"
OUT_DIR="$ROOT_DIR/packing/dpkg"
OUT_FILE="$OUT_DIR/mimocode_${VERSION}_${ARCH_DEB}.deb"

rm -rf "$DEB_ROOT"
mkdir -p "$DEB_ROOT/DEBIAN" "$DEB_ROOT$PREFIX/bin" "$OUT_DIR"
chmod 755 "$DEB_ROOT" "$DEB_ROOT/DEBIAN"
install -m755 "$NATIVE_BIN" "$DEB_ROOT$PREFIX/bin/mimo"

cat >"$DEB_ROOT/DEBIAN/control" <<EOF
Package: mimocode
Version: $VERSION
Architecture: $ARCH_DEB
Maintainer: $MAINTAINER
Section: utils
Priority: optional
Description: MiMoCode AI coding assistant for Termux (native bionic runtime)
Depends:
Conflicts: mimocode-wrapper
EOF

INSTALLED_SIZE=$(du -sk "$DEB_ROOT" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >>"$DEB_ROOT/DEBIAN/control"

cat >"$DEB_ROOT/DEBIAN/postinst" <<'POSTINST'
#!/data/data/com.termux/files/usr/bin/bash
set -e
echo "MiMoCode (native) for Termux installed"
echo "Run: mimo --version"
exit 0
POSTINST
chmod 755 "$DEB_ROOT/DEBIAN/postinst"

dpkg-deb --build "$DEB_ROOT" "$OUT_FILE"
echo "DEB package created: $OUT_FILE"
