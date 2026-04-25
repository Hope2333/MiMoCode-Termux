# Plan: Termux plugin packaging restructure + docs/hooks/AVIF updates

## Scope
- opencode-plugins-termux (workspace path: `/data/data/com.termux/files/home/develop/opencode-plugins-termux`) becomes a router-only repo; each `plugins/*` subproject is independently buildable/packagable with **dpkg-deb** + **makepkg**.
- Add `plugins/example` template subproject.
- opencode-termux packages a **docs bundle** + **skills index** (plugin/hook + runtime/troubleshoot; build/packaging referenced via URLs only).
- Add **pre/post remove** lifecycle hooks (safe-by-default).
- Convert all images to **AVIF** (ffmpeg CRF 48) and update references.

## Constraints
- No risky build/package runs on local Termux.
- Use debug host **192.168.10.118** for build/package verification.
- Keep hook behavior safe-by-default (network off, strict off).
- Avoid editing generated outputs (`artifacts/`, `packaging/*/work`, `packaging/*/pkg`, built `.deb`/`.pkg.tar.*`).

## Dependencies / References
- opencode-termux hook runner: `/data/data/com.termux/files/home/develop/opencode-termux/scripts/hooks/run-system-skills.sh`
- opencode-termux packaging: `/data/data/com.termux/files/home/develop/opencode-termux/scripts/package/package_deb.sh`, `/data/data/com.termux/files/home/develop/opencode-termux/scripts/package/package_pacman.sh`, `/data/data/com.termux/files/home/develop/opencode-termux/packaging/pacman/PKGBUILD`
- opencode-plugins-termux current builder: `/data/data/com.termux/files/home/develop/opencode-plugins-termux/tools/plugin-builder.sh` (to be replaced by per-plugin packaging)

## Plan Steps (Ordered)
1. **Design router-only top-level Makefile (opencode-plugins-termux)**
   - Update `/data/data/com.termux/files/home/develop/opencode-plugins-termux/Makefile` to delegate to `plugins/<name>/Makefile` targets only.
   - Provide `list` target (enumerate `plugins/*`), `deb`, `pacman`, `all`, `clean` routing.

2. **Create per-plugin packaging subprojects**
   - For each existing plugin under `/data/data/com.termux/files/home/develop/opencode-plugins-termux/plugins/*`:
     - Add `Makefile` with targets: `fetch`, `stage`, `deb`, `pacman`, `all`, `clean`.
     - Add `scripts/` (fetch/stage/build helpers as needed).
     - Add `packaging/deb/DEBIAN/control` template and packaging script for dpkg-deb.
     - Add `packaging/pacman/PKGBUILD` and makepkg wrapper (align with opencode-termux patterns).
   - Ensure staged tree mirrors `dist/index.js` to root `index.js` (avoid `dist` plugin name).

3. **Add `plugins/example` template**
   - Create `/data/data/com.termux/files/home/develop/opencode-plugins-termux/plugins/example/` with full packaging scaffold.
   - Include minimal README explaining usage and expected layout.

4. **Docs bundle + skills index (opencode-termux)**
   - Add `/data/data/com.termux/files/home/develop/opencode-termux/docs/skills-index.md` with concise entries (plugin/hook + runtime/troubleshoot; build/packaging via URLs).
   - Update `/data/data/com.termux/files/home/develop/opencode-termux/docs/README.md` to include the skills index entry.
   - Update `/data/data/com.termux/files/home/develop/opencode-termux/scripts/build.sh` to copy selected docs into `$STAGED_PREFIX/share/opencode/docs/` during staging.

5. **Lifecycle hooks for remove events**
   - Add deb `prerm`/`postrm` generation in `/data/data/com.termux/files/home/develop/opencode-termux/scripts/package/package_deb.sh`.
   - Add pacman `pre_remove`/`post_remove` in `/data/data/com.termux/files/home/develop/opencode-termux/packaging/pacman/PKGBUILD` (or `.install` if adopted).
   - Ensure hook runner is invoked with `OPENCODE_HOOK_STRICT=0` and `OPENCODE_HOOK_ENABLE_NETWORK=0`.
   - Update hook docs (`/data/data/com.termux/files/home/develop/opencode-termux/docs/system-skills-hook-architecture.md`) to mention new events.

6. **AVIF conversion policy**
   - Define a documented policy (new doc or update existing) for `ffmpeg -crf 48` AVIF conversion.
   - Convert all images to `.avif` and update all Markdown references under both repos as applicable.
   - Do not keep original images unless explicitly needed (reduce package size).

7. **Verification (debug host only for packaging)**
   - On 192.168.10.118, run per-plugin `make deb/pacman` and ensure artifacts appear.
   - Validate docs bundle exists in staged prefix.
   - Ensure hooks are present and safe-by-default.

## Risks / Rollback
- Packaging scripts are destructive: keep verification on debug host; revert scripts if packaging fails.
- AVIF conversion may break references: update references systematically; rollback by restoring original image extensions if needed.
- Hook changes can break install/uninstall: keep safe-by-default flags; revert hook scripts if needed.
