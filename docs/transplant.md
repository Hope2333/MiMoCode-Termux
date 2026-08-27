# MiMoCode native transplant pipeline (ported from opencode-termux)

> Condensed port of the authoritative surgery doc:
> [opencode-termux `docs/transplant.md`](https://github.com/Hope2333/opencode-termux/blob/native-android/docs/transplant.md).
> This file records only what is MiMoCode-specific: format facts, adaptation
> points, and commands. For grafting principles (BUN_COMPILED.size publish,
> BSS-safe placement, reloc vs plain-offset size modes), failure playbooks and
> FAQ, read the source doc.

## What this is

The same revive surgery proven on opencode 1.2.x–1.18.x, applied to
**MiMoCode** (`XiaomiMiMo/MiMo-Code`, probed on latest `v0.1.13`). Upstream
ships no Android build, so we graft the MiMoCode standalone module graph onto
the official **oven-sh android Bun 1.4.0** ELF (same shared base verdict as the
opencode line) and produce a single bionic executable that runs directly on
Android (API >= 28), zero glibc.

Ported files live under `tools/transplant/` (pipeline + configs); the Makefile
exposes a thin wrapper target `mimo-transplant`.

## Format facts for mimo (probed v0.1.13)

Evidence: opencode-termux `.omo/evidence/task-mimo-compat-probe.log`
(verdict B = portable).

| Property | Value |
|---|---|
| Tarball | upstream asset `mimocode-linux-arm64.tar.gz`; ELF member is **root-level `mimo`** (not `/bin/opencode`) |
| Graph format | **section format** (same family as opencode >= 1.18): module graph lives inside the `.bun` PROGBITS section |
| `.bun` section | offset `0x5940000`, size `0x21792A6` (35,099,302 B); head u64 LE = 35,099,294 (= size − 8, i.e. BUN_COMPILED.size) followed by `/$bunfs/`; tail `[Offsets32][marker16="\n---- Bun! ----\n"]` |
| Offsets32 (`<QIIIIII`) | byte_count=35099246, mod_off=35087082, mod_len=12116, entry=33, argv0=35099198, argv1=47, flags=3 |
| Record layout | **52 B stride**, n = **233 modules** (no 36→52 conversion needed) |
| Producer bun | **v1.3.14**; argv0 string `--user-agent=mimocode/0.1.10 --use-system-ca --` |
| Graft base | oven-sh android bun **1.4.0** (`tools/transplant/config/bun-bind.json`: target=1.4.0, `bun-linux-aarch64-android.zip`) |
| Revive size mode | **plain-offset** (auto-selected: base bun >= 1.4 publishes BUN_COMPILED.size as an unbiased payload vaddr constant; no RELA extension) |

## Embedded glibc `.so` blobs (runtime implications)

Three glibc-linked aarch64 `ET_DYN` shared objects are embedded RAW inside the
`.bun` region of the mimo binary:

| Blob | Raw offset in tgz ELF | Notes |
|---|---|---|
| watcher-like daemon | 115,729,899 | DT_NEEDED: libc / libgcc / libm / libpthread / libstdc++ |
| pty-like helper | 118,757,252 | exports the forkpty family |
| libopentui.so | 122,700,953 | carries the `libopentui.so` soname |

Implications: these are **format-compatible** (they do not block the graft),
but at runtime they are glibc-linked and Android/bionic cannot load them as-is.
Same problem class as the opencode line: TUI rendering and file watching stay
degraded until each blob is replaced by a bionic build (opencode-termux already
solved libopentui via equal-length swap with an NDK-built bionic `.so`, and the
watcher via a standalone inotify daemon). That swap work is **follow-up scope,
not part of this port**.

## Adaptation points vs the opencode-termux source

1. `transplant.py extract_step`: new `--member` knob (default `/bin/opencode`
   suffix match preserved unchanged; MiMoCode passes `--member mimo`).
2. `transplant.py`: new `--product` knob for output naming (default stem
   `opencode` unchanged; MiMoCode uses `--product mimocode` → products
   `mimocode-native` / `mimocode-native-revived`).
3. `probe_assemble.py download_bun`: resolves the base URL from
   `config/bun-bind.json` (target=1.4.0) instead of the legacy hardcoded
   bun-1.3.14 URL — required because section-format graphs must use a >= 1.4
   base.
4. `config/patches.json`: added empty range `{min: 0.1.0, max: 0.99.99,
   bun_layout: "52", patches: []}` so mimo versions resolve to a graceful
   patch no-op (the opencode undici patch has zero hits in the mimo graph and
   stays recorded under its own range for lineage).
5. `Makefile`: thin `mimo-transplant` wrapper target; existing opencode-style
   targets untouched.

## Commands

```bash
# One-shot pipeline (downloads the 1.4.0 android bun on first run):
make mimo-transplant VER=0.1.13 TGZ=/path/to/mimocode-linux-arm64.tar.gz

# Equivalent direct call with all knobs explicit:
python3 tools/transplant/transplant.py all \
    --ver 0.1.13 --tgz /path/to/mimocode-linux-arm64.tar.gz \
    --member mimo --product mimocode

# Output:
#   artifacts/transplant/<ver>/module-graph.bin
#   artifacts/transplant/<ver>/report.json
#   artifacts/transplant/<ver>/mimocode-native-revived   <- runnable ELF

./artifacts/transplant/<ver>/mimocode-native-revived --version
```

Pipeline steps for mimo: extract (--member mimo) → detect (section mode) →
convert skipped (already 52 B) → patch (no-op via empty range) → assemble
skipped (section format grafts directly) → revive (plain-offset) → verify
(execve asserts the version string).

## Verification boundary

CI green ≠ runnable. Final acceptance requires running the revived binary on a
real Android/Termux device (`--version` exit 0 with the expected version
string). Isolated-HOME testing needs a warm cache mirror or the binary hangs at
startup (see source doc FAQ).
