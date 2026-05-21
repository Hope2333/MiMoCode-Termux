# opencode-termux

Termux-focused packaging and runtime workflow for OpenCode (AI coding assistant).

## Overview

This repo produces **Termux-compatible OpenCode packages** (deb + pacman) from the
upstream `opencode-linux-arm64` binary. Two build routes exist:

| Route | Branch | Runtime | Status |
|-------|--------|---------|--------|
| **glibc (legacy)** | `glibc` | glibc Bun + bun-termux-loader wrapper | ✅ Stable |
| **native-android (CI)** | `main` | CI-automated wrap pipeline | ✅ Operational |

The `main` branch uses a **GitHub Actions CI workflow** to automate wrapping.
Legacy local-build users should switch to the `glibc` branch.

---

## Install

```bash
# Path A: apt/pkg (recommended)
apt install -y glibc-repo
apt update
apt install -y glibc openssl-glibc
apt install -y /path/to/opencode_<version>_aarch64.deb

# Path B: pacman
pacman -Syu
pacman -S glibc openssl-glibc
pacman -U /path/to/opencode-<version>-aarch64.pkg.tar.xz
```

Releases: https://github.com/Hope2333/opencode-termux/releases

---

## CI Build Pipeline

A GitHub Actions workflow (`.github/workflows/build-native-android.yml`) automates
binary production on `ubuntu-latest`:

```
workflow_dispatch (manual)
  ↓ Resolve version from npm
  ↓ Install QEMU aarch64 emulation
  ↓ Download opencode-linux-arm64 from npm
  ↓ Download Android Bun (diagnostic)
  ↓ Analyze binary (find marker, extract JS payload)
  ↓ Attempt cross-compile (diagnostic)
  ↓ Clone bun-termux-loader → wrap with pre-built aarch64 artifacts
  ↓ Create bundle + upload
  ↓ Write status JSON
```

### Key artifacts

| Artifact | Description |
|----------|-------------|
| `opencode-termux-aarch64` | **Wrapped Termux binary** (the deliverable) |
| `opencode-linux-arm64` | Original upstream binary (from npm) |
| `opencode-js-payload.bin` | Extracted JS bytecode |
| `build-status.json` | Full manifest with sha256 checksums |

---

## Local Build (glibc route)

For local/offline builds, switch to the `glibc` branch:

```bash
git checkout glibc
make all VER=<version> PKG=both
make batch VERS='<major.minor.[start-end]>' PKG=deb ODIR=~/oct-out
```

Requires: `glibc` + `openssl-glibc`, bun-termux-loader (auto-cloned), real Termux aarch64 device.

---

## Research: Native Android Bun

Bun v1.3.14 added native Android builds. See `docs/native-android-research.md`.

**Key finding**: Android Bun runs on Termux but `bun build --compile` fails
(due to `/data/` permission restrictions). Full native migration awaits
upstream `--target=bun-linux-aarch64-android` support.

---

## Repository layout

```
.github/workflows/
  build-native-android.yml     CI automated build pipeline
  prebuild-armv7.yml           armv7 cross-toolchain handoff
tools/
  produce-local.sh             Local runtime build (glibc route)
  prebuilt/                    Pre-built aarch64 wrapper+shim for CI
scripts/
  build.sh                     Stage install prefix
  package/package_deb.sh       DEB builder
  package/package_pacman.sh    Pacman builder
  launcher.sh                  Runtime dispatcher
docs/
  native-android-research.md   Android Bun research
  13-opencode-runtime-build.md Runtime build details
```

---

## Safeguards

- TTY cleanup on exit
- Stale lock cleanup
- statx seccomp shim (preloaded via launcher, disable with `OPENCODE_DISABLE_STATX_SHIM=1`)
- `OPENCODE_DISABLE_DEFAULT_PLUGINS=1` (default)

## Metadata

Maintainer: `Hope2333(幽零小喵) <u0catmiao@proton.me>`

## Upstream

- OpenCode: <https://github.com/anomalyco/opencode>
- bun-termux-loader: <https://github.com/Hope2333/bun-termux-loader>
