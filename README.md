# MiMoCode-Termux — pure-android branch

**MiMoCode**, packaged for Termux. This repo wraps the upstream MiMoCode binary
(`mimocode-linux-arm64` from [MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) releases)
for Android/Bionic via bun-termux-loader. glibc is required at runtime (the wrapper
loads it via userland exec).

---

## Dependencies

| Package | Required? | Why |
|---------|-----------|-----|
| `glibc` | ✅ Yes | Wrapped binary is glibc-linked; wrapper loads via glibc's ld.so |
| `openssl-glibc` | ✅ Yes | HTTPS/TLS for API calls |
| `bash` | ✅ Yes | Launcher script |
| `ncurses` | ✅ Yes | TUI support |

```bash
# Install dependencies
apt install -y glibc-repo
apt update
apt install -y glibc openssl-glibc

# Then install mimocode
apt install -y /path/to/mimocode_<version>_aarch64.deb
```

### Path B: pacman (secondary)

```bash
pacman -Syu
pacman -S glibc openssl-glibc
pacman -U /path/to/mimocode-<version>-aarch64.pkg.tar.xz
```

---

## What this branch provides

- ✅ **Real AI coding assistant** (`mimocode --version`)
- ✅ deb + pacman package output
- ✅ Plugin lifecycle system (install/update/rollback)
- ✅ TTY/signal cleanup launcher
- ✅ System-skill hooks (post-install/upgrade/remove)
- ✅ Batch build (`make batch VERS='0.1.0'`)
- ✅ Release upload automation (`make release-upload`)

---

## How it works

The upstream binary (`mimocode-linux-arm64` from upstream MiMo-Code releases) is a
**glibc-linked Bun-compiled application**. It contains the Bun runtime +
AI coding code compiled into a single ELF executable.

To make it run on Android/Bionic, **bun-termux-loader** prepends a thin
Bionic wrapper:

```
┌──────────────────────────────────────────────┐
│ Bionic wrapper ELF (~12KB)                    │
│   - Reads /proc/self/exe                      │
│   - Finds BUNWRAP1 metadata                   │
│   - Extracts embedded binary                  │
│   - Userland exec via glibc's ld.so           │
├──────────────────────────────────────────────┤
│ BUNWRAP1 metadata                             │
├──────────────────────────────────────────────┤
│ Original opencode binary (glibc Bun + JS)     │
│   - Interpreter: /lib/ld-linux-aarch64.so.1   │
│   - Entry: compiled-app mode (RX seg base)    │
│   - ---- Bun! ---- marker + JS bytecode       │
└──────────────────────────────────────────────┘
```

**Userland exec**: Instead of `execve()` (which would update `/proc/self/exe`
and break Bun's JS location), the wrapper mmap()s glibc's `ld.so` and jumps
to its entry point, keeping `/proc/self/exe` pointing to itself.

---

## Install

```bash
# Path A: apt/pkg (recommended)
apt install -y glibc-repo
apt update
apt install -y glibc openssl-glibc
apt install -y /path/to/mimocode_<version>_aarch64.deb

# Path B: pacman
pacman -Syu
pacman -S glibc openssl-glibc
pacman -U /path/to/mimocode-<version>-aarch64.pkg.tar.xz
```

Releases: https://github.com/Hope2333/MiMoCode-Termux/releases

---

## Usage

```bash
mimocode --version          # → 0.1.0
mimocode run "hi"           # AI chat
mimocode run --mode=dev .   # development mode
mimocode serve              # API server mode
mimocode web                # web interface
```

---

## Build

### Local build (Termux)

```bash
# Single version
make all VER=0.1.0 PKG=both

# Batch build
make batch VERS='0.1.0' PKG=both ODIR=~/mc-out MIX=1
```

### Build + release upload

```bash
make release-upload TAG=Push260611 VERS='0.1.0'
# Defaults: TAG=Push<YYMMDD>, REPO=Hope2333/MiMoCode-Termux, PKG=both
```

### Build flow

```
make all VER=0.1.0 PKG=both
  → clean (rm -rf artifacts/staged, packaging work dirs)
  → runtime (tools/produce-local.sh: npm download + bun-termux-loader wrap)
  → stage (scripts/build.sh: copy to prefix tree)
  → deb (scripts/package/package_deb.sh)
  → pacman (scripts/package/package_pacman.sh)
```

---

## Repository layout

```
.github/workflows/
  build-pure-android.yml      CI automated build pipeline (WIP)
tools/
  produce-local.sh            Download from npm + wrap
  prebuilt/                   Pre-built aarch64 wrapper+shim for CI
scripts/
  build.sh                    Stage prefix
  launcher.sh                 Runtime dispatcher (cleanup + exec)
  package/package_deb.sh      DEB builder
  package/package_pacman.sh   Pacman builder
  hooks/run-system-skills.sh  Post-install/upgrade hooks
patches/
  0001-android-support.patch   Upstream patches (WIP)
docs/
  native-android-research.md  Research: zero-glibc approaches
```

## Launcher safeguards

- TTY cleanup on exit (soft/hard depending on exit code)
- Stale lock cleanup (`*.lock` in `$XDG_STATE_HOME`)
- `MIMOCODE_DISABLE_DEFAULT_PLUGINS=1` (default)

## Metadata

Maintainer: `Hope2333(幽零小喵) <u0catmiao@proton.me>`

## Related

- OpenCode upstream: <https://github.com/anomalyco/opencode>
- bun-termux-loader: <https://github.com/Hope2333/bun-termux-loader>
- Android-native Bun: <https://github.com/Hope2333/bun-termux> (pure-android branch)
- Upstream Bun (Android builds): <https://github.com/oven-sh/bun>

## Acknowledgments

MiMoCode-Termux is based on [opencode-termux](https://github.com/Hope2333/opencode-termux),
which packages upstream [OpenCode](https://github.com/anomalyco/opencode) for Termux.
All credit for the AI engine and wrapping technology belongs to their respective authors.
