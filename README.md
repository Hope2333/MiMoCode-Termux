# opencode-termux

OpenCode AI coding assistant for Termux/Android.

## Dependencies

**Required at runtime:**

| Package | Why |
|---------|-----|
| `glibc` | OpenCode binary is glibc-linked; bun-termux-loader loads it via glibc's ld.so |
| `openssl-glibc` | HTTPS/TLS for API calls |

```bash
# Install dependencies (Termux apt)
apt install -y glibc-repo
apt update
apt install -y glibc openssl-glibc

# Then install opencode
apt install -y /path/to/opencode_<version>_aarch64.deb
```

**Optional (separate package):**

| Package | Repo | Provides |
|---------|------|----------|
| `bun` (Android-native) | `Hope2333/bun-termux` | JS runtime (0 glibc) |

---

## What this is

This package ships the **real OpenCode AI coding assistant**, compiled from
upstream source via `bun build --compile`, then wrapped for Android/Bionic
using bun-termux-loader. It runs on Termux via glibc's dynamic linker.

```
opencode --version  →  1.15.7  (real OpenCode)
```

---

## How it works

```
[opencode command]
       ↓
  bun-termux-loader wrapper (Bionic ELF)
       ↓
  extracts embedded glibc Bun runtime + OpenCode JS
       ↓
  userland exec via glibc's ld-linux-aarch64.so.1
       ↓
  OpenCode AI runs normally
```

The wrapper binary is an aarch64 Bionic PIE that uses **userland exec**
(mmap + jump, not execve) to load glibc's dynamic linker and the embedded
OpenCode runtime, keeping `/proc/self/exe` pointing to the wrapper so Bun
can find its embedded JavaScript.

---

## Constraints (why not zero-glibc yet)

### We tried

| Approach | Result |
|----------|--------|
| **Android-native Bun** (v1.3.14 Bionic binary) | ✅ `bun run` works, ❌ `bun build --compile` fails (`/data/` permission) |
| **JS bundle** (`bun build --target=bun`) | ❌ Native modules (`@opentui/solid`) prevent clean bundling |
| **Binary surgery** (swap glibc Bun → Android Bun) | ❌ Android Bun lacks compiled-app entry point code |
| **Fork Bun + add Android compile target** | ⏳ Long-term, requires Zig/C++ changes to Bun |

### Current path

**bun-termux-loader wrapping** — proven, production-stable. The wrapped binary
includes both the glibc runtime linker and the OpenCode application code in a
single Bionic-friendly package. glibc is required at runtime but is a standard
Termux package (`apt install glibc`).

### Future possibility

When upstream Bun supports `--target=bun-linux-aarch64-android`, we can
switch to native Android Bun as the runtime, eliminating the glibc dependency.

---

## Build

```bash
# Build one version
make all VER=1.15.7 PKG=both

# Batch build multiple versions
make batch VERS='1.15.[1-7]' PKG=both

# Build + upload to release
make release-upload TAG=Push260522 VERS='1.15.[1-7]'
```

---

## Repository

```
tools/
  produce-local.sh         Download from npm + wrap
  prebuilt/                Pre-built wrapper + shim for CI
scripts/
  build.sh                 Stage prefix
  launcher.sh              Runtime dispatcher
  package/package_deb.sh   DEB builder
  package/package_pacman.sh  Pacman builder
patches/                   Upstream OpenCode patches (WIP)
```

## Related

- OpenCode upstream: <https://github.com/anomalyco/opencode>
- bun-termux-loader: <https://github.com/Hope2333/bun-termux-loader>
- Android-native Bun: <https://github.com/Hope2333/bun-termux> (pure-android branch)
- Upstream Bun: <https://github.com/oven-sh/bun>
