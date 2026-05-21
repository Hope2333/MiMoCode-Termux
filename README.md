# opencode-termux — pure-android

Android-native Bun runtime packaged for Termux.
**Zero glibc. Zero bun-termux-loader. Zero statx shim.**

This branch ships [Android Bun](https://bun.sh) (Bionic-linked) as the `opencode`
command. It is a JavaScript/TypeScript runtime — not the OpenCode AI coding assistant
application itself. OpenCode application integration requires a future JS bundle.

**Looking for OpenCode AI assistant?** See the `glibc-legacy` branch for the
full OpenCode experience (requires glibc).

---

## Install

```bash
# No glibc required. Just install the package.
apt install -y /path/to/opencode_1.3.14_aarch64.deb
# or
pacman -U /path/to/opencode-1.3.14-1-aarch64.pkg.tar.xz
```

## Usage

```bash
opencode --version    # → Bun 1.3.14
opencode run hi.ts    # run a TypeScript file
opencode repl         # start Bun REPL
opencode install      # Bun package manager
```

This is **Android-native Bun** — the full Bun runtime (JS runtime, package
manager, bundler, test runner) running directly on Termux without glibc.

## What this provides

- ✅ **Android-native Bun** (Bionic-linked, `/system/bin/linker64`)
- ✅ Zero glibc dependency
- ✅ Zero bun-termux-loader
- ✅ Zero statx shim
- ✅ Works on arm64 and x86_64 Android
- ✅ Launcher with TTY/signal cleanup

## What this does NOT provide (yet)

- ❌ OpenCode AI coding assistant (requires JS bundle — TBD)
- ❌ `opencode run "hi"` → OpenCode AI chat (use `glibc-legacy` branch)

## Build from source

```bash
# Clone and build Android Bun package
git clone https://github.com/Hope2333/opencode-termux
cd opencode-termux
tools/produce-local.sh      # downloads Android Bun
scripts/build.sh            # stage prefix
scripts/package/package_deb.sh
```

## OpenCode AI assistant (current status)

The `opencode` command on this branch runs **Android-native Bun** (a JS runtime).
The actual OpenCode AI coding assistant is NOT yet available on pure-android because:

1. OpenCode's source code depends on native modules (`@opentui/solid`, etc.)
   that require `bun build --compile` to bundle correctly
2. `bun build --compile` does not work on Android (filesystem permission
   restrictions on `/data/`)
3. The CI attempts to build a JS bundle from source, but native module
   dependencies prevent a clean `--target=bun` bundle

**For the full OpenCode AI experience**, use the `glibc-legacy` branch:
```bash
git checkout glibc-legacy
make all VER=<version> PKG=both
```

The pure-android branch focuses on providing a clean, glibc-free Android Bun
runtime. OpenCode application integration will be enabled when upstream Bun
supports `--target=bun-linux-aarch64-android` or when native modules are
available for Bionic.

## Repository layout

```
tools/
  produce-local.sh       Download Android Bun from GitHub
scripts/
  build.sh               Stage prefix
  launcher.sh            Runtime dispatcher (cleanup + exec)
  package/package_deb.sh DEB builder
  package/package_pacman.sh  Pacman builder
docs/
  native-android-research.md  Android Bun research
```

## Related

- Upstream Bun: <https://github.com/oven-sh/bun>
- OpenCode: <https://github.com/anomalyco/opencode>
- glibc-legacy branch: full OpenCode + glibc
