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

## OpenCode integration (future)

OpenCode's application code is currently compiled into a glibc-linked binary.
To make it work with Android-native Bun:
1. Extract JS source from the compiled binary (tools like `bun-demincer`)
2. Rebuild as JS bundle: `bun build --target=bun --outfile=bundle.js`
3. Run with Android Bun: `bun run bundle.js`

See `docs/native-android-research.md` for details.

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
