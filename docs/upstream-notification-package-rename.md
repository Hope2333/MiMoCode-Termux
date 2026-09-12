# 上游同步告知单：opencode-termux 包名变更 + 主线切换

> 来源仓库：`Hope2333/opencode-termux`（branch `native-android`）
> 性质：单向信息同步，不催促、不设 deadline。下游（MiMoCode-Termux）经盘点后**无需同步更名**，详见第 2 节。

## 0. 背景核查说明（bg_2cb1920d 状态）

本告知单原计划引用后台任务 `bg_2cb1920d` 的盘点产出。核查结论：**该后台任务已丢失**——本会话 `oc_background list` 返回为空，无任何可续接任务。以下全部事实以下游仓库 `git log` 与工作区实际状态为准重建（HEAD `0c01f65`，branch `pure-android`，工作区干净），并逐条附证据。

## 1. 上游变更摘要

上游 opencode-termux 正在执行"包名变更 + 主线切换"三件套（预计随 Push 27/28 落地，以 [releases 页](https://github.com/Hope2333/opencode-termux/releases) 为准）：

1. **glibc 包更名**：`opencode` → `opencode-glibc`，带 `Replaces: opencode` / `Breaks: opencode (<< 版本)` 实现旧名平滑替换，同时保留与 native 线的互斥（`Conflicts: opencode-native`）。
   - 上游事实源：`packing/deb/DEBIAN/control:1,7-9`；`scripts/package/package_deb.sh:50,56-58`（heredoc 为功能真源，control 模板是孤儿模板）；`packing/pacman/PKGBUILD:1,9,10`（`pkgname=opencode-glibc` + `replaces=('opencode')` + `conflicts=('opencode' 'opencode-native')`）。
   - 命令入口 `bin/opencode` 与运行时前缀 `lib/opencode/` **不变**，只有包管理器层包名变。
2. **native bionic 线继承 `opencode` 名成为 stable 主线**（自 Push 27/28 起）：零 glibc 依赖的 native 包从 BETA prerelease 转正，占用 `opencode` 包名；glibc 线降为附录维护。
   - 上游事实源：`packing/pacman/PKGBUILD.native:3,13,14`（`pkgname=opencode-native` + `conflicts=('opencode')` + `provides=('opencode')`）；README 顶部 transition notice。
3. **新增 `opencode-glibc-standalone` 冻结回退包**：单版本冻结、命令入口 `opencode-glibc`、独立 lib 前缀 `usr/lib/opencode-glibc/`、独立 state 目录，`conflicts=()` + `provides=('opencode-glibc')`，可与 native `opencode` 及 `opencode-glibc` 共存，仅作回退用。
   - 上游事实源：`packing/pacman/PKGBUILD.standalone:1,4-6,15-16`；`scripts/build.sh:10-16`（`STANDALONE=1` 独立 prefix 模式）。

三包终态模型：`opencode` = native stable；`opencode-glibc` = 附录互斥线；`opencode-glibc-standalone` = 冻结回退共存包。

## 2. 对下游的影响面（基于 MiMoCode-Termux 实际仓库状态）

盘点结论先行：**下游包名 `mimocode` 与上游三包（`opencode` / `opencode-glibc` / `opencode-native` / `opencode-glibc-standalone`）包名互异、文件路径零重叠，无需同步更名**。逐文件依据如下：

| 下游文件 | 现状（行号实测） | 影响判断 |
|---|---|---|
| `packing/deb/DEBIAN/control:1` | `Package: opencode` | **唯一真实隐患**。该模板是孤儿模板（实际 deb 由 `scripts/package/package_deb.sh` heredoc 生成，模板不被消费，与上游 B1 前状态同构），但模板名恰为上游 native stable 即将占用的 `opencode` 包名。若未来有人启用该模板构建，产出的 deb 会与上游 stable 包正面撞名。建议择机清理为 `mimocode`（纯卫生修复，无功能影响）。 |
| `scripts/package/package_deb.sh:26,34` | `OUT_FILE=mimocode_${VERSION}_${ARCH_DEB}.deb`；heredoc `Package: mimocode`，无 Replaces/Breaks/Conflicts | 无需改动。包名独立，与上游无包级冲突。 |
| `packing/pacman/PKGBUILD:1,19-24` | `pkgname=mimocode`；`prepare()` 检查 `lib/mimocode/runtime/mimocode` + `bin/mimo`，无 conflicts/replaces 字段 | 无需改动。下游装 `usr/lib/mimocode/*` + `bin/mimo`，上游装 `usr/lib/opencode*/` + `bin/opencode*`，文件级零重叠，两套包可共存。 |
| `scripts/package/package_pacman.sh:30-31` | 临时文件名 `.makepkg-opencode.conf` / `.PKGBUILD.opencode.tmp` 残留上游旧名字样 | 纯内部临时文件，无功能影响（与上游 B1 收口前同款问题）。可选清理，不紧急。 |
| `tools/produce-local.sh:2-3,10` | 主线仍是 glibc wrapper 线：下载 `mimocode-linux-arm64`（源 `XiaomiMiMo/MiMo-Code`，:10）+ bun-termux-loader 包装 | 无需改动。下游运行时来源与上游（anomalyco/opencode）完全不同，上游主线切换不影响下游 runtime 获取逻辑。 |
| `tools/transplant/`（全套）+ `Makefile:157`（`mimo-transplant` 目标） | transplant 管线已移植（commit `966b856`，verdict-B adaptations） | 移植基线为上游更名前状态。上游 B1/B2/B3 改动集中在 packing/package 层，未触及 `transplant.py`/`revive_patch.py` 等管线本体，**管线无需回移**。 |
| `scripts/build.sh:7-15` | mimocode 布局（`lib/mimocode/`），无 `STANDALONE` 变量 | 下游无 standalone 模式。属**可选引入项**而非必须：若下游未来需要"冻结回退共存包"，可参考上游 `PKGBUILD.standalone` 模式（`provides` + `conflicts=()` + 独立 lib 前缀 + 独立 state 目录），并须规避上游已实测的 docs 文件级重叠缺陷（见第 3 节 C2）。 |
| `packing/pacman/` 目录 | 仅 `PKGBUILD` / `PKGBUILD.aarch64` / `PKGBUILD.armv7l` / `select_pkgbuild.sh`，无 `PKGBUILD.standalone` | 同上，standalone 为可选引入。 |

补充：下游 `git log` 确认移植脉络完整——`1a4acb1` rebrand → `fc46b8e`/`060c8ce` runtime 下载 → `4657664` packing 统一迁移 → `966b856` transplant 移植 → `0c01f65` HEAD。工作区干净，无未提交改动。

## 3. 上游真机验证结论引用（C1/C2/C3，均已真机实测）

以下结论来自上游 `.omo/notepads/package-rename-transition/learnings.md`（2026-08-28），供下游未来做类似迁移/共存设计时直接引用：

- **C1 迁移 runbook（真机通过，2 条命令）**：`pacman -Rdd --noconfirm opencode` → 单事务 `pacman -U --noconfirm <native-pkg> <standalone-pkg>`（零文件冲突）。关键坑：① 有插件包时必须 `-Rdd`——插件包依赖虚拟 `opencode`，Termux pacman 的 required-by 检查连 `-d` 都不放行；② 非交互 shell 下 `-R`/`-U` 都要 `--noconfirm`；③ 验证旧名包不存在要用 `pacman -Qq | grep -x opencode`（`pacman -Q opencode` 会因 `provides` 回退解析而误报存在）。
- **C2 回退路径 + 已知缺陷**：回退 `pacman -Rdd --noconfirm opencode-native` → `pacman -U --noconfirm opencode-glibc` 本体验证通过，但暴露 **standalone docs 13 项文件级重叠缺陷**——standalone 包也装 `usr/share/opencode/docs/*`（13 项全为 docs，与新名 glibc 包完全重叠），包级 `conflicts=()` 拦不住文件级冲突，两包共存时后装方必然失败。修复方向：standalone 去掉 docs 或两包 docs 路径分离。**Termux pacman `--overwrite` glob 必须用包内全路径** `data/data/com.termux/files/usr/...`（root=/，包内路径带 `data/data` 前缀）；`usr/share/...` 形式静默不匹配、事务照样失败。
- **C3 互斥拒绝 + `--ask 4` 三级矩阵**：① 裸 `--noconfirm` 装互斥包 → 包级 conflicts 拒绝（`unresolvable package conflicts detected`，exit=1），事务原子无半装；② `--ask 4` 仍拒绝——冲突问题自动答 yes 后被 required-by 检查拦截；③ `--ask 4 -dd --overwrite '<docs 全路径 glob>'` 可单命令换线（exit=0），但带 `-dd` 绕过安全检查 + docs 双重所有权两个 caveat。干净的一键换线前提是先修 standalone docs 重叠。

## 4. PR 时机建议

**三选一结论：等上游 Push tag 正式发布后再提 PR**（即选项二）。

理由：

1. **下游无紧急动作项**。第 2 节已证包名/文件路径零冲突，告知单本身不携带必须立即落地的代码变更；唯一行动项（孤儿模板 `packing/deb/DEBIAN/control:1` 清理为 `mimocode`）是卫生修复，随时可做。
2. **上游终态尚未定稿**。27/28 切换的最终形态（正式 tag 名、release notes 措辞、standalone docs 重叠是否已修）未落定，现在提 PR 引用上游状态可能随即过时，反而制造第二次同步成本。
3. **触发条件明确**：观察到上游 releases 页出现 27/28 切换 tag（native `opencode` stable 转正 + `opencode-glibc` 更名发布）后，下游一次性提一个小 PR：清理孤儿模板包名 + 可选收录本告知单 + （如决定引入）standalone 模式参考实现。体量小、表述确定、一次到位。
4. 若下游恰有临近版本节点（如 0.1.11），可搭车在该节点前合并，避免单独为一个文档同步发版。

—— 以上为信息同步，何时采纳由下游自行决定。
