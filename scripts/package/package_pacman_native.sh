#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TRANSPLANT_ROOT="${TRANSPLANT_ROOT:-$ROOT_DIR/artifacts/transplant}"
PACKAGER_NAME="${PACKAGER_NAME:-Hope2333(幽零小喵) <u0catmiao@proton.me>}"
PKGREL="${PKGREL:-1}"

command -v makepkg >/dev/null 2>&1 || {
	echo "Error: makepkg not found"
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

NATIVE_BIN="${MIMO_NATIVE_BIN:-$TRANSPLANT_ROOT/$VERSION/mimocode-native-revived-tui}"
[[ -x "$NATIVE_BIN" ]] || {
	echo "Error: native binary not found or not executable: $NATIVE_BIN"
	exit 1
}

cd "$ROOT_DIR/packing/pacman"
rm -rf "$ROOT_DIR/packing/pacman/pkg" "$ROOT_DIR/packing/pacman/src"

TMP_MAKEPKG_CONF="$ROOT_DIR/packing/pacman/.makepkg-mimocode-native.conf"
TMP_PKGBUILD="$ROOT_DIR/packing/pacman/.PKGBUILD.mimocode-native.tmp"
cleanup() {
	rm -f "$TMP_MAKEPKG_CONF" "$TMP_PKGBUILD"
}
trap cleanup EXIT

cp /data/data/com.termux/files/usr/etc/makepkg.conf "$TMP_MAKEPKG_CONF"
printf "\nPACKAGER=%q\n" "$PACKAGER_NAME" >>"$TMP_MAKEPKG_CONF"

cp "$ROOT_DIR/packing/pacman/PKGBUILD.native" "$TMP_PKGBUILD"
sed -i "s/^pkgver=.*/pkgver=$VERSION/" "$TMP_PKGBUILD"
sed -i "s/^pkgrel=.*/pkgrel=$PKGREL/" "$TMP_PKGBUILD"

MIMO_NATIVE_BIN="$NATIVE_BIN" REPO_ROOT="$ROOT_DIR" makepkg --config "$TMP_MAKEPKG_CONF" -f --noconfirm -p "$TMP_PKGBUILD"

echo "Pacman package created under: $ROOT_DIR/packing/pacman"
