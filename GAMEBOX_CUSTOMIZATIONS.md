# Gamebox 定制化修改清单与工作流

> 本文件是 Gamebox 项目的**单一真理来源**（Single Source of Truth）：
> 1. 记录 Gamebox 相对上游 `appshubcc/Bettbox` 的所有定制化修改
> 2. 定义 `main` / `gamebox` 双分支工作流
> 3. 提供完整的"同步上游 / rebase / 解决冲突"操作流程
> 4. 任何修改都要带 `// [Gamebox]` 注释，并同步更新本文件

**当前 `gamebox` 分支 HEAD**：`337ea70f`（merge 了 `origin/main` v1.19.7 = `1fb8806f`；同步过程见 §3.20）
**当前 `main` 分支 HEAD**：`1fb8806f`（严格等于 `upstream/main`，**不可变**）
**当前发布版本**：`pubspec.yaml` = `1.19.7+2026102201`；`version.json` = `1.19.6+2026101601`（⚠️ **两者不一致，发版前要同步**，见 §8.4）
**当前发布时间**：`2026-10-20`

---

## 目录

- [0. 工作流约定（最重要）](#0-工作流约定最重要)
- [1. 同步上游 SOP（详细步骤）](#1-同步上游-sop详细步骤)
- [2. 解决 rebase / merge 冲突的标准流程](#2-解决-rebase--merge-冲突的标准流程)
- [3. 定制化项清单](#3-定制化项清单)
  - [3.1 默认深色主题 + 简体中文固定](#31-默认深色主题--简体中文固定)
  - [3.2 备份与恢复隐藏](#32-备份与恢复隐藏)
  - [3.3 内核配置默认值](#33-内核配置默认值)
  - [3.4 增强工具](#34-增强工具)
  - [3.5 检查更新（不走 GitHub releases）](#35-检查更新不走-github-releases)
  - [3.6 应用标识](#36-应用标识)
  - [3.7 首页 / 关于页](#37-首页--关于页)
  - [3.8 Panel 面板（用户认证）](#38-panel-面板用户认证)
  - [3.9 i18n 锁 zh_CN（设置页只显示简体中文）](#39-i18n-锁-zh_cn设置页只显示简体中文)
  - [3.10 节点/订阅持久化（重登不丢节点 + 多账号分桶）](#310-节点订阅持久化重登不丢节点--多账号分桶)
  - [3.11 Inno Setup 安装器（只保留中文）](#311-inno-setup-安装器只保留中文)
  - [3.12 订阅静默同步（profile_revision 心跳驱动）](#312-订阅静默同步profile_revision-心跳驱动)
  - [3.13 隐藏订阅入口（防止误操作配置）](#313-隐藏订阅入口防止误操作配置)
  - [3.14 渲染后端固定 Skia（对齐 upstream v1.19.6）](#314-渲染后端固定-skia对齐-upstream-v1196)
  - [3.15 检查更新修复（2026-10-20）](#315-检查更新修复2026-10-20)
  - [3.16 托盘退出通知面板下线（修在线设备不立即归零）](#316-托盘退出通知面板下线修在线设备不立即归零)
  - [3.17 显示文字全部从 Bettbox 改为 Gamebox + 删启动 splash + 登录页居中（2026-10-20）](#317-显示文字全部从-bettbox-改为-gamebox--删启动-splash--登录页居中2026-10-20)
  - [3.18 安卓端首页默认卡片布局（补回 userProfile + 重排）](#318-安卓端首页默认卡片布局补回-userprofile--重排)
  - [3.19 安卓端默认开关调整（4 项）](#319-安卓端默认开关调整4-项)
  - [3.20 同步上游 v1.19.7 的冲突处理记录](#320-同步上游-v1197-的冲突处理记录)
- [5. 资源文件](#5-资源文件)
- [6. 注释规范](#6-注释规范)
- [7. 提交规范](#7-提交规范)
- [8. 打包 / 发布 / 测试](#8-打包--发布--测试)

---

## 0. 工作流约定（最重要）

### 0.1 分支模型

```
上游 appshubcc/Bettbox (upstream, 只 fetch 不 push)
  │
  │ fork
  ▼
mouren1988/Bettbox (origin, 自己的 fork)
  ├── main     ← 严格 = upstream/main, 永远只读
  └── gamebox  ← 基于 main 叠加 Gamebox 定制, 唯一允许写定制的分支
```

### 0.2 三个铁律

1. **`main` 永远等于 `upstream/main`** —— 不直接 commit、不直接修改。
2. **`gamebox` = `main` + Gamebox 全部定制** —— 所有定制代码、文档、配置都 commit 到这里。
3. **打包发布用 `gamebox` 分支** —— `flutter build` 和 `dart run package_windows.dart` 必须在 `gamebox` 上执行。

### 0.3 远程仓库配置

```bash
# 查看当前 remote
git -C "D:\iGame+\Gamebox" remote -v
# 预期:
#   origin    https://github.com/mouren1988/Bettbox.git (fetch/push)
#   upstream  https://github.com/appshubcc/Bettbox.git (fetch)
#   upstream  DISABLED (push)            ← 关键：绝对不能推 upstream
```

**禁止**：
- 改 upstream URL（永远是 `appshubcc/Bettbox`）
- 用 HTTPS 协议时不带 PAT 推送
- 把 `origin` 推成其他仓库

### 0.4 commit 标记

所有 Gamebox 定制代码必须带 `// [Gamebox]` 注释；commit message 用 `Gamebox:` 前缀：

```dart
// [Gamebox] 默认深色主题
final themeMode = ThemeMode.dark;
```

```
Gamebox: 默认深色主题 + 简体中文固定

- lib/models/config.dart: themeMode 默认 dark
- lib/application.dart: locale 固定 zh-Hans-CN
```

**为什么必须标记**：rebase 时一眼能识别定制 commit，冲突解决时永远保留。

---

## 1. 同步上游 SOP（详细步骤）

### 1.1 完整流程

```bash
cd D:\iGame+\Gamebox

# === 阶段 A: 同步 main 到上游最新版 ===

# A1. 拉取上游最新
git fetch upstream

# A2. 切到 main
git checkout main

# A3. 强制重置 main 到 upstream/main
#     ⚠️ 用 --hard 是因为 main 必须严格等于 upstream,不能有偏差
#     ⚠️ local main 上如果有 dirty,先 stash 或 commit(实际不该有)
git reset --hard upstream/main

# A4. 推 main 到 fork
#     用 --force-with-lease 而非 --force(防止覆盖别人)
git push origin main --force-with-lease

# === 阶段 B: gamebox 跟随 main 更新 ===

# B1. 切回 gamebox
git checkout gamebox

# B2. 优先 rebase,冲突多时改用 merge
git rebase main
# 冲突处理见 §2

# B3. 推送 gamebox
#     fast-forward 时直接 push
#     有新定制 commit 时 git push -u origin gamebox
git push origin gamebox
# 如果 rebase 改了已推送的 commit,需要:
# git push --force-with-lease origin gamebox
# ⚠️ force push 前一定确认没有人基于 gamebox 开发

# === 阶段 C: 验证 ===

# C1. 三端一致
git rev-parse main upstream/main          # 应都是 7006a026
git rev-parse gamebox origin/gamebox      # 应一致

# C2. 跑测试(见 §8)
flutter build windows --release --dart-define=APP_ENV=stable
```

### 1.2 判断 main 落后 upstream 多少

```bash
git fetch upstream
echo "=== upstream 领先 main 的 commit ==="
git log --oneline main..upstream/main
echo "=== main 领先 upstream 的 commit (应为 0) ==="
git log --oneline upstream/main..main
```

如果 `upstream/main..main` 不为 0 —— **main 已被污染**，需要重置。

### 1.3 当 upstream 没新版本时

`git log --oneline main..upstream/main` 输出为空，跳过阶段 A，只做阶段 B 的 gamebox 自定义 commit。

---

## 2. 解决 rebase / merge 冲突的标准流程

### 2.1 通用规则

**优先级**（从高到低）：

1. **带 `// [Gamebox]` 标记的代码** —— **永远保留**
2. **Gamebox 依赖的上游函数**（如 `state.dart` 的 `openUserManual`）—— 手动重新移植
3. **upstream 新增的同位置代码** —— 用注释同时保留两版本
4. **upstream 删除的 Gamebox 引用** —— 删对应 Gamebox 引用
5. **冲突标记 `<<<<<<<` / `=======` / `>>>>>>>`** —— 解决后必须删干净

### 2.2 冲突类型与处理

#### 类型 A：Gamebox 修改 vs upstream 修改同一行

```dart
<<<<<<< HEAD (gamebox)
// [Gamebox] 固定简体中文
const locale = Locale('zh', 'CN');
=======
const locale = Locale('en', 'US');
>>>>>>> main (upstream)
```

**处理**：保留 Gamebox 版本（已带 `[Gamebox]` 标记）。

```dart
// [Gamebox] 固定简体中文（参考 §3.1,即使选别的语言也被覆盖回 zh-CN）
const locale = Locale('zh', 'CN');
```

#### 类型 B：upstream 删了 Gamebox 依赖的代码

例如 upstream 删了 `state.dart` 的 `openUserManual()` 函数，但 Gamebox 还在 `about.dart` 调用它。

**处理**：手动重新移植该函数到 gamebox。

```dart
// 1. 找 upstream 删除位置的 commit
git log --all --oneline -S "openUserManual" -- lib/state.dart

// 2. 看删除的代码
git show <commit>^:lib/state.dart | grep -A 10 "openUserManual"

// 3. 手动加回 gamebox 分支（用 [Gamebox] 标记）
//    文件: lib/state.dart (或新建 lib/state_gamebox.dart)
Future<void> openUserManual() async {
  // [Gamebox] 从 upstream v1.19.5 <commit> 移植
  // 原始位置: lib/state.dart
  // 移植原因: upstream 在 v1.19.6 删除,但 about.dart 仍在用
  final manualUrl = 'https://github.com/mouren1988/Bettbox/wiki';
  // ... 原始实现
}
```

#### 类型 C：upstream 新增的同位置代码

例如 upstream 在 `clash_config.dart` 新增了 `externalController` 默认值，但 Gamebox 的默认值在另一行。

**处理**：用注释同时保留两版本。

```dart
// [Gamebox] UA 默认 Gamebox（不带版本号,见 §3.3）
const defaultUA = 'Gamebox';
// ↑ Gamebox 默认值
// ↓ upstream v1.19.5 新增的 externalController 默认值
const defaultExtController = false;
```

#### 类型 D：upstream 删了 Gamebox 引用

例如 upstream 删了 `enum.dart` 里的 `outboundMode` 枚举（Gamebox §3.7 已删），现在 upstream 又加回来。

**处理**：
- 如果 upstream 加的枚举值在 `yaml` 仍能启用（Gamebox §3.7 设计），**保留 Gamebox 删除状态**
- 重新加注释：`// [Gamebox] 永久删除出站模式（即使 upstream 加回,Gamebox 仍删）`

### 2.3 rebase 中断后处理

```bash
# rebase 中途报错
git status
# 输出: interactive rebase in progress; onto 7006a026
# You are currently rebasing branch 'gamebox' on '7006a026'.

# 1. 解决冲突文件
#    编辑冲突文件,删 <<<<<<< / ======= / >>>>>>> 标记
#    git add <file>

# 2. 继续 rebase
git rebase --continue

# 3. 如果 rebase 某个 commit 不再需要(Gamebox 已 obsolete)
git rebase --skip

# 4. 如果整个 rebase 走错方向
git rebase --abort
```

### 2.4 rebase 后清理

```bash
# 1. 检查是否有遗留的 .orig / .rej 文件
find . -name "*.orig" -o -name "*.rej" 2>/dev/null
# 删掉: rm -f $(find . -name "*.orig")

# 2. 跑代码扫描确认所有 [Gamebox] 段还在
grep -rn "\[Gamebox\]" lib/ windows/ arb/ | wc -l
# 应大于 0(具体数见 §3 各项)

# 3. 跑 flutter analyze
flutter analyze --no-pub
# 必须 0 error,warning 可接受
```

> ⚠ **为什么 `flutter analyze` 是必跑项（不能跳）**：
> git 只检测「同一 hunk 双方都改」的冲突。上游在**Gamebox 没碰过的上下文**里引用了
> Gamebox 已删除/改名的符号时，git 会「自动合并成功」，但代码根本编译不过。
>
> 实例：上游 v1.19.7 在 `lib/enum/enum.dart` 又加回了对已被 Gamebox 永久删除的
> `outboundMode` / `outboundModeV2` 枚举值的引用（`_variantGroups` 和 `nativeSize` switch 各一处），
> 3 个 upstream 新测试也断言了它们。git 一个冲突都没报，`flutter analyze` 才抓到
> 4 个 `undefined_enum_constant` / `non_type_as_type_argument`。
>
> 详见 §3.20。

### 2.5 验证清单（rebase 完成后必查）

**先验内核同步（最重要，优先级高于所有 Dart 侧检查）**：

| 项 | 命令 | 期望 |
|---|---|---|
| **内核目录与上游一致** | `git diff --stat HEAD <upstream-main> -- core/` | **输出为空**。`core/` 是 in-tree vendored（不是 submodule，仓库里没有 `.gitmodules`），所以 Gamebox 侧一旦有本地改动就会在这里显示。空 = 内核与上游逐字节相同 |
| 内核文件数一致 | `git ls-tree -r --name-only HEAD -- core/ \| Measure-Object -Line` | 与上游同一数字（v1.19.7 时是 **1096**）|

> ⚠ **为什么内核这条要单独拎出来**：Gamebox 对 `core/` **没有任何定制**（不要在 `core/` 里改代码），
> 内核版本完全由「是否把上游 `core/` 整棵树带过来」决定。
> 一次 merge 如果只带了 `lib/` 没带 `core/`（或反过来 core 冲突被误跳过），
> Dart 侧 `flutter analyze` 照样 0 error —— **只有这条 diff 能发现**。
>
> 内核版本号本身在 `core/Clash.Meta/constant/version.go` 里是空的（`Version = ""`），
> 构建时才通过 `-ldflags` 注入，所以**别指望在源码里 grep 到 `v1.19.33`**，
> 要确认版本就比对 `core/` 整棵树，或看构建产物的版本输出。

**再验 Dart 侧定制**：

| 项 | 命令 | 期望 |
|---|---|---|
| 主题 dark | `grep "themeMode.*dark" lib/models/config.dart` | 命中 |
| locale zh | `grep "zh-Hans-CN\|zh_CN" lib/application.dart lib/views/tools.dart` | 命中 |
| 隐藏 backup | `grep "隐藏备份" lib/views/tools.dart` | 命中 |
| UA = Gamebox | `grep "UserAgent.*Gamebox\|defaultUA.*Gamebox" lib/models/clash_config.dart` | 命中 |
| gh-proxy | `grep "gh-proxy.org" lib/models/clash_config.dart` | ⚠ **v1.20.0 起已主动去掉**（见 §3.3 注），命中 0 属正常；镜像改由用户自己在「资源」页配 |
| BundleMRS gh-proxy | `grep "BundleMRS" lib/views/resources.dart` | ⚠ 同上，`resources.dart` 已改回直连 GitHub releases |
| 仓库 fork 指向 | `grep "repository" lib/common/constant.dart` | 命中 mouren1988 |
| 1 天更新 | `grep "defaultUpdateDuration.*1\b\|defaultUpdateDuration.*Duration.*days.*1" lib/common/constant.dart` | 命中 |
| 蓝奏云 | `grep "lanzoup" lib/common/constant.dart` | 命中 |
| ~~fast 动画~~ | ⚠️ **已作废**：上游删掉了这个可配置项，改用硬编码 `midDuration = 200ms`。**不要再当定制项检查**，命中 0 属正常 |
| about.dart do-not-rebase 标记 | `head -5 lib/views/about.dart` | 第一行有标记 |
| profile url hash | `grep "sha256" lib/models/profile.dart` | 命中 |
| 不删 deleteAllProfiles | `grep -c "deleteAllProfiles" lib/panel/panel_auth.dart` | 0（已删 3 处）|
| 锁 zh_CN | `grep "_localeOptions" lib/views/tools.dart` | 命中 1 项 |
| profile_revision 心跳同步 | `grep "lastSeenProfileRevision\|remoteProfileRevision" lib/panel/panel_auth.dart` | 命中 ≥ 6 处 |
| 解析 profile_revision 工具 | `grep "_extractProfileRevision" lib/panel/panel_auth.dart` | 命中 ≥ 3 处（声明 + 调用）|
| 隐藏订阅入口 | `grep "隐藏订阅入口" lib/common/navigation.dart` | 命中 |
| 隐藏订阅 | `grep "PageLabel.profiles" lib/common/navigation.dart` | 仅在注释块（`// NavigationItem` 段）|
| 托盘退出发 logout | `grep "clearPanelSubscriptions" lib/controller.dart` | 命中 `handleExit` 里的调用 |
| logoutPanelAccount 统一路径 | `grep -c "clearPanelSubscriptions" lib/panel/panel_auth.dart` | ≥ 2（logoutPanelAccount + clearPanelDataOnExit）|
| 安装器无 english | `grep "english" windows/packaging/exe/inno_setup.iss` | 应无残留 |
| AppId 不同于上游 | `grep "app_id" windows/packaging/exe/make_config.yaml` | 不是 upstream 默认值 |
| Impeller 无条件禁 | `Get-Content windows/runner/main.cpp -Encoding Unicode \| Select-String "ImpellerSwitch"` | 命中且**无 `#ifdef`** 包裹(`main.cpp` 历史是 UTF-16 LE 编码,普通 `grep`/`rg` 字节级会匹配不到,**用 PowerShell `Select-String -Encoding Unicode` 或 IDE 查看**) |
| `BETTBOX_COMPATIBLE_BUILD` cmake 块已删除 | `grep "if.*BETTBOX_COMPATIBLE_BUILD" windows/runner/CMakeLists.txt` | 应**无残留**(只有 §3.14 注释里描述性提到 "原 `if(...BETTBOX_COMPATIBLE_BUILD...)` 块" 的字符串) |

---

## 3. 定制化项清单

### 3.1 默认深色主题 + 简体中文固定

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| themeMode | `dark` | `lib/models/config.dart` | `// [Gamebox] 默认深色主题` |
| locale | 固定 `zh-Hans-CN` | `lib/application.dart` `lib/state.dart` | `// [Gamebox] 固定简体中文` |

**rebase 注意点**：
- upstream 如果改 `MaterialApp.locale` 走 `_appLocale()` 函数,**保留 Gamebox 写死**
- upstream 如果加新的 `themeMode` 选项（`system` / `light` / `dark`）,**Gamebox 仍默认 dark**

### 3.2 备份与恢复隐藏

| 项 | 状态 | 文件 | 说明 |
|---|---|---|---|
| 侧边栏 `backupAndRecovery` | **隐藏** | `lib/views/tools.dart:124` | `// [Gamebox] 隐藏备份与恢复` |
| 悬浮面板 `Backup` 入口 | **隐藏** | `lib/widgets/floating_panel.dart`（新 architecture 才有）| `// [Gamebox] 隐藏备份` |

**rebase 时如果 upstream 新增了备份入口**,按相同方式注释掉 + 加 `[Gamebox]` 注释。

### 3.3 内核配置默认值

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| 连通性测试 URL | `https://cf.cloudflare.com/...` | `lib/models/clash_config.dart` | `// [Gamebox] 默认 CF 测试链接` |
| 查找进程 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 查找进程默认开启` |
| 外部控制 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 外部控制默认开启` |
| 控制密码 | **空** | `lib/models/clash_config.dart` | `// [Gamebox] 控制密码为空` |
| 全局 User-Agent | `Gamebox`（无版本号；上游 Bettbox 是 `clash.meta`,本项目刻意不带版本号）| `lib/models/clash_config.dart` | `// [Gamebox] UA 默认 Gamebox（不带版本号）` |
| BundleMRS.7z URL | `https://github.com/appshubcc/bett-rules/releases/download/latest/BundleMRS.7z`（**v1.20.0 起已改回直连**，与上游一致）| `lib/views/resources.dart` | `// [Gamebox] 资源页可自行编辑 URL` |
| GEO 默认 URL（生成器）| 3 条**直连** GitHub releases：`mmdb` / `asn` / `geosite`（**v1.20.0 起已去掉 `v4.gh-proxy.org` 前缀**）| `lib/models/generated/clash_config.g.dart:_GeoXUrlFromJson` | `// [Gamebox] 保持与上游一致的 3 条 URL` |
| GEO 默认 URL（源码）| 同上,3 条 `@Default()` 全部是 GitHub 直连（`lib/models/clash_config.dart:GeoXUrl`）| `lib/models/clash_config.dart` | `// [Gamebox] GeoXUrl default URLs` |
| 虚拟网卡 | **开启（桌面端）**| `lib/models/clash_config.dart` | `// [Gamebox] 桌面端默认开启虚拟网卡` |
| 系统代理 | **关闭** | `lib/models/clash_config.dart` | `// [Gamebox] 系统代理默认关闭` |
| ICMP 转发 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] ICMP 转发默认开启` |
| TUN 模式（Windows）| **开启** | `lib/models/clash_config.dart` | `// [Gamebox] TUN 默认开启` |

**rebase 注意点**：
- upstream 如果加新的 default URL,**跟上游保持直连**（v1.20.0 起 Gamebox 已不再强制加 `v4.gh-proxy.org` 前缀；用户想走镜像自己在「资源」页改 URL）
- upstream 如果改 `UserAgent` 字段名,**保留 Gamebox 的 `Gamebox` 值**
- upstream 如果删除 `cf.cloudflare.com` 测试 URL,**改用 `https://www.gstatic.com/generate_204`**

### 3.4 增强工具

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| 托盘增强 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 托盘增强开启` |
| 隐藏托盘菜单 | 规则 / 全局 / 直连 **隐藏** | `lib/common/tray.dart` | `// [Gamebox] 托盘菜单隐藏规则、全局、直连` |
| 高优先级 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 高优先级开启` |
| 悬浮面板 | **开启** | `lib/models/config.dart` | `// [Gamebox] 悬浮面板开启` |
| 联动开关 | **关闭** | `lib/models/config.dart` | `// [Gamebox] 联动开关默认关闭` |
| 延迟动画 | ❌ **该定制已作废，保持和上游一致** —— 上游把这个可配置项删掉了，现在全局用硬编码常量 `midDuration = Duration(milliseconds: 200)`（`lib/common/constant.dart`）。Gamebox 不再单独定制 | `lib/common/constant.dart` | 无 `[Gamebox]` 标记（跟随上游） |
| 回环保护 | **跟随上游**（`@Default(true)`）| `lib/models/config.dart` | `// [Gamebox] 跟随上游` |

### 3.5 检查更新（不走 GitHub releases）

| 项 | 值 | 文件 | 注释 |
|---|---|---|---|
| 检查更新端点 | `https://raw.githubusercontent.com/mouren1988/Bettbox/refs/heads/gamebox/version.json`（直接读 fork 的 `gamebox` 分支根目录的 `version.json`）| `lib/common/request.dart` `lib/common/constant.dart` | `// [Gamebox] 检查更新走 raw.githubusercontent.com 读 fork 的 gamebox 分支上的 version.json` |
| 仓库 | `mouren1988/Bettbox`（URL 模板里用 `$repository` 拼,sync 上游时务必确认这里指向 fork）| `lib/common/constant.dart` | `// [Gamebox] 仓库指向 fork（不上游原版）` |
| 数据源 | `gamebox` 分支根目录下的 `version.json`(**不**走 GitHub releases;用户不想发版）| `lib/common/constant.dart` | `const updateCheckUrl = 'https://raw.githubusercontent.com/$repository/refs/heads/gamebox/version.json';` |
| `version.json` 字段 | `{ "version": "1.19.7+2026101701", "notes": "v1.19.7" }`（`version` 包含 `+build` 后缀;`notes` 是弹窗正文,通常写成版本号本身如 `v1.19.7`）| `https://github.com/mouren1988/Bettbox/blob/gamebox/version.json` | 用户自己维护;同步 `packageInfo.version+buildNumber` |
| `version.json.notes` 约定 | **写版本号本身**（如 `v1.19.7`）—— 整个字符串直接显示在「发现新版本」弹窗大字里。**不要**写 changelog 列表（太长用户不愿看）| `version.json` | 每次发版改 version 即可,notes 跟 version 同步（如 `v1.19.7`）|
| 下载链接 | `https://v10.lanzoup.com/b013a2b1wh`（蓝奏云盘,**不**走 GitHub releases）| `lib/common/constant.dart` | `const downloadUrl = 'https://v10.lanzoup.com/b013a2b1wh';` |
| 客户端映射 | `version.json.version` → `tag_name` (仅用于内部版本比较); `version.json.notes` → 弹窗大字内容; `downloadUrl` (constant.dart) →「前往下载」按钮的链接。**修复:原版渲染把 tag_name 显示在大字、notes 解析成 bullet 列表两个版本信息都出现,现已合并为只用 notes 作大字**(controller.dart forceCheck 段) | `lib/common/request.dart` `checkForUpdate()` `lib/controller.dart:1216` | 内部用 `tag_name`/`body` 字段返回（兼容下游 controller / about 零改动）|
| 全局 User-Agent | `Gamebox`（无版本号;上游 Bettbox 是 `clash.meta`,本项目刻意不带版本号）| `lib/models/clash_config.dart` | `// [Gamebox] UA 默认 Gamebox（不带版本号）` |
| 自动检查周期 | **1 天**（上游默认 28 天;常量 `defaultUpdateDuration`）| `lib/controller.dart` `lib/common/constant.dart` | `// [Gamebox] 自动检查周期改为 1 天` |
| 触发时机 | 启动时 + 距上次 > 1 天 | `lib/controller.dart:1167` | `final forceCheck = (now - lastCheckTime) > defaultUpdateDuration.inMilliseconds;` |

**rebase 注意点**：
- upstream 如果改 `version.json` 数据源（**走 GitHub releases**）,**立刻改回 raw.githubusercontent.com**
- upstream 如果改 `repository` 默认值,确保 `mouren1988/Bettbox` 仍在
- upstream 如果重构 `checkForUpdate()` 拿回原始 `response.data`（Map）做解析,**保留 Gamebox 的 `ResponseType.bytes` + `_decompressIfNeeded` 路径**（dio 5.x 在 Content-Encoding=gzip 时不会自动解压,会拿到转义 UTF-16 Map,详见下方故障记录）

### 3.6 应用标识

| 项 | 值 | 文件 | 注释 |
|---|---|---|---|
| AppIdentity.displayName | `Gamebox` | `lib/common/identity.dart` | `// [Gamebox] 个性标题 Bettbox → Gamebox` |
| 全局搜索替换 | `Bettbox` → `Gamebox`（除 git 仓库名/包名/外链）| 全局 | 同步脚本 `rg -l Bettbox lib/ \| xargs sed -i 's/Bettbox/Gamebox/g'` |

### 3.7 首页 / 关于页

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 首页出站规则卡片 | **永久删除**（不让客户用全局;dashboard `DashboardWidget.outboundMode` 和 `outboundModeV2` 枚举值已从 `lib/enum/enum.dart` 删除,widget 文件保留为 stub;yaml 仍可启用全局模式）| `lib/enum/enum.dart` `lib/views/dashboard/widgets/outbound_mode.dart` | `// [Gamebox] 永久删除出站模式` |
| 连通性测试置顶平台 | `gemini, discord, youtube`（上游是 `spotify, discord, youtube`）| `lib/models/config.dart` | `// [Gamebox] 置顶平台 spotify→gemini` |
| 关于页 | **固定不随上游更新** | `lib/views/about.dart` | 见 §4 |
| 贡献者头像 | 只显示 `mouren1988` 本地头像 | `lib/views/about.dart` `assets/images/avatars/mouren1988.jpg` | `// [Gamebox] 贡献者只显示仓库维护者` |
| 关于页链接 | 使用说明 / 检查更新 / Telegram 群 / QQ 群 | `lib/views/about.dart` | `// [Gamebox] 关于页链接偏好` |

### 3.8 Panel 面板（用户认证）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 启动 Gate | `ValueListenableBuilder(panelUnlocked)` 未解锁显示 `PanelLoginGate`,解锁后显示 `HomePage` | `lib/application.dart` (`_AppHome` widget) | `// [Gamebox] 启动登录 Gate` |
| 修改密码入口 | 退出账号时显示 | `lib/views/dashboard/widgets/user_profile.dart` | `// [Gamebox] 退出账号菜单` |
| 头像 | 本地 `mouren1988.jpg`(不联网) | `lib/views/about.dart` | `// [Gamebox] 头像本地化` |
| X-Client-OS 平台上报 | 原来写死 `'windows'`,改为 `switch (defaultTargetPlatform)` 动态返回 `'android'` / `'ios'` / `'linux'` / `'macos'` / `'windows'` | `lib/panel/panel_auth.dart` | `// [Gamebox] 按真实平台上报 X-Client-OS` |
| UA 输入框默认值处理 | 内置默认 UA (`defaultGlobalUa = 'Gamebox'`)不预填到输入框;用户自填内容加 `obscureText` 密码掩码 | `lib/views/config/general.dart` | `// [Gamebox] 内置 UA 不回显 / 用户 UA 加掩码` |

### 3.9 i18n 锁 zh_CN（设置页只显示简体中文）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 设置页语言列表 | 只显示「简体中文」一项（`_LocaleItem._localeOptions` 改为 `const [Locale.fromSubtags(...)]`）| `lib/views/tools.dart` | `// [Gamebox] 语言入口只保留简体中文` |
| 显示映射 | `_nativeLocaleNames` 字典保留 `zh_CN` 老 key + 新增 `zh_Hans_CN` key,都映射到「简体中文」| `lib/views/tools.dart` | `// [Gamebox] 字典保留原 key 不动` |
| 当前 locale 显示 | `currentLocale` 强行落到 `_localeOptions` 唯一项（`_LocaleItem.build`）,保证 Radio 始终选中简体中文 | `lib/views/tools.dart` | `// [Gamebox] 即使 appSetting.locale 持久化的是老值...` |
| 持久化兼容 | `appSetting.locale` 如果之前是 en/ja/... 不会被强行擦（防止破坏老用户偏好存储）| `lib/models/config.dart` | 沿用上游存储格式 |
| `otherContributors` 文案 | 6 个 locale 的 arb 全部去掉「(随机排序)」/「(Random Order)」等尾巴;中文用「贡献者」| `arb/intl_*.arb` | 关于页只显示维护者,不再有「随机排序」误导 |
| 关于页 `desc` | 缩短为「Gamebox 基于强大灵活的 Mihomo 内核深度打造,致力于更好的客户端体验。」（去掉「我们的愿景: Connecting Open Source and AI, Accelerating Innovation」英文尾巴）| `arb/intl_zh_CN.arb` | intl_utils 自动重生成 |

> 🐛 **坑：`arb/` 改了 ≠ 生效，`lib/l10n/` 也必须重新生成。**
> 2026-10-23 核对 v1.19.7 时发现：`otherContributors` 和关于页 `desc` 这两项定制**只改了 arb，从没跑过
> `dart run intl_utils:generate`** —— 合并前的 `lib/l10n/intl/messages_en.dart` 里仍然是
> 上游原文 `"Other Contributors (Random Order)"`，也就是说这两条定制**写进了文档但实际从未生效**。
> 本次重新生成后才真正生效（现已是 `"Contributors"`）。
> **以后改任何 arb 文案，务必跟一次 `dart run intl_utils:generate` 并确认 `lib/l10n/` 有 diff**，
> 否则改了个寂寞。

**为什么这么做**：
- 上游 `MaterialApp.locale` 写死 `zh-Hans-CN`（见 §3.1）,**选别的 locale 实际不生效**（下次冷启动被覆盖）
- 但设置页 Radio 列表还显示 7 项（zh_CN/zh_TC/en/ru/fa/ja/ko）,**会误导用户以为能切换**
- 锁成只显示 zh_CN 消除误导
- 不强行擦 `appSetting.locale`,**保持存储格式兼容**（老用户升级不会因为 locale 字段缺失出 bug）

### 3.10 节点/订阅持久化（重登不丢节点 + 多账号分桶）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| `Profile.normal()` id 生成 | **URL 类订阅**用 `sha256(url).substring(0, 16)` 当 id（**文件导入保留**时间戳 id,因为没 url）| `lib/models/profile.dart` | `// [Gamebox] URL 类订阅用 url sha256 前 16 位当 id：同 url 永远同 id...` |
| `loginPanelAccount` 删 `deleteAllProfiles` | 登录时**不**再清空本地 profile。旧逻辑:删所有 profile → 拉新订阅 → selectedMap 被空集合覆盖。**新逻辑:按 url hash upsert,保留旧 selectedMap**。| `lib/panel/panel_auth.dart:loginPanelAccount` | `// [Gamebox] 删 deleteAllProfiles：保留旧 profile/selectedMap...` |
| `_importSubscription` 保留旧 selectedMap / unfoldSet | 按 url hash 查本地同 id profile,复用其 `selectedMap` 和 `unfoldSet`,避免 upsert 时被空集合覆盖 | `lib/panel/panel_auth.dart:_importSubscription` | `// [Gamebox] 按 url sha256 当 id；先查本地同 id 的 profile...` |
| `_importSubscription` 显式切 currentProfileId | `addProfile` 只在 `currentProfileId==null` 时才设,**切账号场景（currentProfileId 非 null）兜不住**。在 `_importSubscription` 末尾显式调 `setCurrentProfileId(created.id)` | `lib/panel/panel_auth.dart:_importSubscription` | `// [Gamebox] 显式切到刚拉的 profile：删除「退出账号→删 deleteAllProfiles」...` |
| 新增 `setCurrentProfileId` controller 方法 | 公开 `currentProfileIdProvider` 的 setter,供 `_importSubscription` 等场景显式切换 | `lib/controller.dart` | `// [Gamebox] 显式切到指定 profile（面板登录/切账号时用）...` |
| `logoutPanelAccount` 删 `deleteAllProfiles` | **退出账号也保留**本地订阅,**跟托盘退出逻辑统一**（托盘退出原本就不删）。下次登录按 url hash 复用。| `lib/panel/panel_auth.dart:logoutPanelAccount` | `// [Gamebox] 删 deleteAllProfiles：跟托盘退出统一逻辑...` |
| `clearPanelDataOnExit` 删 `deleteAllProfiles` | **进程级退出**也保留本地订阅（之前会删 yaml）| `lib/panel/panel_auth.dart:clearPanelDataOnExit` | `// [Gamebox] 删 deleteAllProfiles：进程级退出也保留本地 profile/selectedMap...` |

**为什么这么做（用户问题）**：

- **Q1:选完节点托盘退出再回来变成默认**——根因不是「托盘退出丢 selectedMap」（托盘退出只 `savePreferences` + `window.hide`,不删任何东西）,而是 **`_importSubscription` 用 `Profile.normal()` 创建空 selectedMap 的 profile,然后 `addProfile` 的 `setProfile` upsert 把数组里旧 profile 的 selectedMap 覆盖为空**。老时间戳 id 不会撞上,每次都新建 → 旧的被覆盖。
- **Q2:托盘退出 vs 退出账号逻辑不一致**——确实不一致。托盘退出只 `savePreferences`,退出账号（`logoutPanelAccount`）会 `deleteAllProfiles` 删 yaml 文件 + 清 currentProfileId。**统一为「都不删本地订阅」**。
- **Q3:不删订阅文件,登录能更新订阅/规则集吗**——**能**。`Profile.saveFile(bytes)` 会覆盖 yaml 文件（规则集、proxy 节点、userinfo 都更新）,但**不动 config.json 里的 selectedMap**。新方案用 url hash id + 复用旧 selectedMap,两者兼顾。
- **Q4:多账号本地多份订阅,切换能精确切吗**——**能**。url hash id 保证「账号 A」和「账号 B」id 永远不同,各自留底;`selectedMap` 按 id 分桶,互不污染。**首次登录账号 B 时,B 还没 selectedMap,落默认**;切回 A 时 A 的 selectedMap 还在。

**行为变化**：

| 场景 | 老行为 | 新行为 |
|---|---|---|
| 首次登录账号 A | 创建 id_A（时间戳）,selectedMap: {} | 创建 id_A = hash(url_A),selectedMap: {}（无变化）|
| 重登账号 A | **新建 id_A2（时间戳不同）,覆盖了原 selectedMap** | upsert 复用 id_A,**selectedMap 保留** |
| 退出账号 A | **删 id_A.yaml + 清 profiles 数组** | **保留 id_A.yaml + profiles 数组不变** |
| 登录账号 B | **id_A 被删,新建 id_B** | id_A 留底,**新建 id_B = hash(url_B)** |
| 切回账号 A | 旧 id_A 已删,**A 的 selectedMap 也丢了** | id_A 还在,**A 的 selectedMap 还在** ✓ |
| 同账号反复登录 ×100 | **100 个 yaml 文件** | 1 个 yaml 文件 ✓ |
| 节点选「日本 03」 | 写入 config.json | 写入 config.json（不变）|

**老时间戳 id 兼容性**：

- 老用户升级后,config.json 里 profile 的 id 是时间戳（如 `1700000000000`）
- 新版本 `Profile.normal()` 对**新创建**的 profile 用 url hash
- 老的时间戳 id profile 文件**不**会被新逻辑误删（`setProfile` 按 id 匹配,老 id 还在数组里就不动它）
- 但**老 id 永远不会被复用**（hash 跟时间戳格式不撞）,**重复登录同账号会创建新的 url-hash id profile**
- 老的 yaml 文件**会变成孤儿**（config.json 不引用,但磁盘还在）——**磁盘残留无害**,UI 看不到,**可以手工清** `<dataDir>/profiles/<时间戳>.yaml`（**不**会丢 config.json 引用过的 profile）

**rebase 注意点**：
- upstream 如果改 `Profile.normal()` 或 `loginPanelAccount` / `logoutPanelAccount` / `clearPanelDataOnExit` / `_importSubscription`,**保留 Gamebox 的修改**（带 `[Gamebox]` 标记）
- upstream 如果改 `addProfile` 的 currentProfileId 行为,**确认** `_importSubscription` 里的 `setCurrentProfileId` 还能正确切到新 profile

### 3.11 Inno Setup 安装器（只保留中文）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| `[Languages]` 段 | 只声明 `chineseSimplified`（去掉 `english` 的 `Name: "english"; MessagesFile: "compiler:Default.isl"`）| `windows/packaging/exe/inno_setup.iss` | `// [Gamebox] 只保留简体中文 CustomMessages` |
| `[CustomMessages]` 段 | 删掉 hardcoded `english.ShuttingDownRunningApp=...` / `english.RemoveUserDataPrompt=...` 两行 | `windows/packaging/exe/inno_setup.iss` | 原因:没声明 `Name: "english"` 时 ISCC 会报 "Unknown language name "english"" |
| Liquid 模板 | `[Languages]` 段用 `{% for %}` 直接渲染,**不用 `{% if %}` 包裹 + `{% else %}` 兜底**（Liquid 的 `for` 块不接受 `else`,而 `if` 包裹是给 fallback english 用的,删掉后整段包裹也不需要了）| `windows/packaging/exe/inno_setup.iss` | `// [Gamebox] ...` |
| `make_config.yaml` `locales` | 只列 zh 一项（删 en）| `windows/packaging/exe/make_config.yaml` | `// [Gamebox] 只保留简体中文：去掉 en，避免安装器弹出 language dialog` |
| 9 个 verification 警告 | `SourceVerificationFailed` / `StatusDownloadFiles` / `StopExtraction` / `VerificationFileHashIncorrect` / `VerificationFileNameIncorrect` / `VerificationFileSizeIncorrect` / `VerificationFileTagIncorrect` / `VerificationKeyNotFound` / `VerificationSignatureDoesntExist` / `VerificationSignatureInvalid` 在 `ChineseSimplified.isl` 未定义 → 走 Default.isl 英文 fallback | — | 不致命,verification 流程出现时是英文消息（业务消息全中文）|

**为什么这么做**：
- 上游 Bettbox 默认带 6 个 locale + english Default,安装时 ISCC 自动弹「Select Language」对话框
- 既然我们只发布中文版（§3.1 固定 locale + §3.9 设置页只显示中文）,**language dialog 完全没有意义**（用户语言选什么都被覆盖回 zh-CN）
- 删 english 后 ISCC 直接进中文安装流程,**节省一个点击**

**rebase / sync 时**：
- 如果 upstream 重新加回 `english` 到 `[Languages]` 段,**立刻删掉**
- 如果 upstream 在 `[CustomMessages]` 加了 `english.*` 行,**同步删掉**
- 同步脚本检查点：`grep -n "english" windows/packaging/exe/inno_setup.iss` 必须只有 ISCC compiler 内置引用（`"compiler:Default.isl"` 那条作为兜底已经删除）|

### 3.15 检查更新修复（2026-10-20）

| 项 | 改前 | 改后 |
|---|---|---|
| `checkForUpdate()` 响应类型 | `ResponseType.json`（dio 5 自动 decode）| `ResponseType.bytes` + 手动 gzip 解压 + `jsonDecode(utf8.decode(...))` |
| 调试输出 | 仅 fail 时的 `checkForUpdate` log | 全链路 `[UPDATE] updateCheckUrl / statusCode / response.data.runtimeType / response.data / remoteVersion / localVersion / hasUpdate` 同时 `commonPrint.debug` + `print`,本机 stdout 直看 |

**为什么这么做(用户问题)**：
用户在本机首次联调时点击「检查更新」没反应,弹窗都不出。
- 起初怀疑 `downloadUrl` 没装到 `checkForUpdate()` 返回的 Map 里 → 加了 `html_url` / `body` / `tag_name` 全字段回填,**没用**
- 调试用 `print(response.data.runtimeType)` → 输出是 **`JSMap`**（dio 把 JSON 解析成了一个特殊集合,而不是 Dart `Map`）
- 进一步 trace → 响应带 `Content-Encoding: gzip`,**dio 5.x 默认不对 `ResponseType.json` + Content-Encoding=gzip 自动解压**,直接拿流里的字节当 JSON 字节喂给 decoder → 解析成 JSMap 而不是 Dart Map,**`is! Map` 判断把它挡掉了**

**修复方法**：
- 改 `ResponseType.bytes` 强制拿原始字节
- 自己 `gzip.decode(rawBytes)`(看 `response.headers['content-encoding']`)
- `jsonDecode(utf8.decode(decompressed))`
- 整段包了 try/catch,失败 log error + return null

**调试开关保留**:
未来 rebase 或环境变更(换 dio 版本/换 raw.githubusercontent.com 代理)再次断流,**直接看 stdout `print('[UPDATE] ...')` 一行行 trace 哪一步挂的**。日志加了 `commonPrint.debug` + `print` 双输出,**生产环境也保留**(本来 check update 1 天才跑一次,日志量可忽略)。

**副作用**:
- 多一次 `gzip.decode` 调用,**网络流量不变**(raw.githubusercontent.com 本来就 gzipped,加手动解压反而不读 Body)
- `print` 同步输出 stdout → 调试器断点不会被它影响
- **`is! Map` 兜底仍在** → 如果 dio 升级或 raw.githubusercontent.com 返回空 JSON,不会崩

**rebase 注意点**:
- upstream 如果改 `checkForUpdate()`,**保留 Gamebox 的 `ResponseType.bytes` + 手动 gzip 路径**(带 `[Gamebox]` 注释)
- upstream 如果删 `_decompressIfNeeded` helper,**整段重写**或重新引入 helper

### 3.12 订阅静默同步（profile_revision 心跳驱动）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 解析 `/v1/me` 响应体的 `user.profile_revision` | 在 `_probePanelMe` 把响应体里的 `profile_revision` 字段(整型,旧版本无此字段时返回 null)抽出,放进 `_PanelMeProbe.remoteProfileRevision` | `lib/panel/panel_auth.dart:_PanelMeProbe` `_probePanelMe` | `// [Gamebox] profile_revision 心跳静默同步` |
| `_PanelSession.lastSeenProfileRevision` 持久化 | 在 `panel_session.json` 加 `lastSeenProfileRevision` 字段(int / double / 数字字符串都接受,缺失或解析失败按 null 处理,不破坏向前兼容)| `lib/panel/panel_auth.dart:_PanelSession` `_saveSession` `_loadSession` | `// [Gamebox] profile_revision 基线` |
| 登录时落基线 | 旧版登录(`_loginLegacy`)登录阶段已经走 /v1/me,顺手把 `profile_revision` 落成基线;passport 登录(`_login`)不在登录阶段多走 /v1/me,`lastSeenProfileRevision` 留 null,首次心跳探测时落基线 | `lib/panel/panel_auth.dart:_loginLegacy` `_login` | `// [Gamebox] 旧版登录阶段已经走 /v1/me,顺手把 profile_revision 落成基线` |
| 心跳比对 + 触发静默更新 | `tickPanelSessionHeartbeat` 末尾:`remote == null` 跳过;`local == null` 只记录不触发拉取;`remote > local` 时调 `globalState.appController.syncProfilesFromPanelRevision()`,成功与否都把 `lastSeen` 抬到 `remote` 避免同一版本号反复触发 | `lib/panel/panel_auth.dart:tickPanelSessionHeartbeat` | `// [Gamebox] 管理端抬 profile_revision 后,心跳静默同步订阅` |
| 绕过 1 天节流的同步方法 | `appController.syncProfilesFromPanelRevision()` 遍历 `profilesProvider` 直接调 `updateProfile(applyUnchanged: false)`,**不**走 `_isProfileUpdateNeeded` 的 1 天节流。心跳拉到了说明面板侧明确有更新,必须立刻生效,不该被节流挡住 | `lib/controller.dart` | `// [Gamebox] profile_revision 心跳静默同步:绕过 _isProfileUpdateNeeded` |
| 仅刷新基线的辅助方法 | `_saveLastSeenProfileRevision(int rev)` 只重写 `lastSeenProfileRevision` 一项,其它字段保持不变 | `lib/panel/panel_auth.dart` | `// [Gamebox] 仅刷新 lastSeenProfileRevision,其它字段保持不变` |
| 解析 user.profile_revision 的工具方法 | `_extractProfileRevision(Object? meParsed)` 从 /v1/me 响应体抽出整型；接受 int / double / 数字字符串 | `lib/panel/panel_auth.dart` | `// [Gamebox] 从 /v1/me 响应体里抽出 user.profile_revision` |

**触发链路（与管理端「订阅更新」按钮对齐）**：

```
面板 admin 抬 user.profile_revision (+1)
  │
  ▼
客户端心跳 60s GET /v1/me（已在 application.dart 调度）
  │
  ▼
tickPanelSessionHeartbeat 比对 session.lastSeenProfileRevision
  │
  ├── remote == null   → 跳过（响应没解析到 revision）
  ├── local  == null   → 仅保存基线（首次心跳不触发拉取）
  └── remote > local   → autoUpdateProfiles() 拉新订阅 → 抬基线
```

**为什么这么做（用户问题）**：
- **Q1:面板上点「订阅更新」/「重置订阅」客户端能否立即生效**——之前是**否**,客户端 24h 定时器、用户手动 sync、客户端重启三种方式任一才能拉取。
- 引入 `profile_revision` 字段后,管理端任何抬升该字段的动作（重置订阅、订阅更新、续费、套餐变更、流量调整、节点分配等,见 mini-panel `AdminController::userSubscriptionDrivingFieldsChanged`）都在 **60s 内** 触发客户端静默拉取。
- **Q2:跟 24h 定时器冲突吗**——不冲突。`autoUpdateProfiles` 内部用 `_isProfileUpdateNeeded` 控增量,revision 同步后定时器照样会跑下一次,但通常已经早被静默拉取过了,等于"提早触发了定时器要做的事"。**24h 定时器保留作兜底**。
- **Q3:跟 iGame-for-Windows 行为对齐吗**——对齐。具体参考 `iGame-for-Windows/src/hooks/use-panel-session-heartbeat.ts` 和 `src/services/mini-panel-auth.ts::syncPanelSubscriptionIfNewerRevision`。Gamebox 同一逻辑由 Dart 实现。
- **Q4:断网/超时会不会误触发拉取**——不会。心跳 `_probePanelMe` 抛异常时 `tickPanelSessionHeartbeat` 整个 return,连基线都不会写,更不会触发拉取。**和现有"断网不算 401"同一条 catch** 兜住。
- **Q5:为什么心跳要调 `syncProfilesFromPanelRevision` 而不是 `autoUpdateProfiles`**——`autoUpdateProfiles` 内部走 `_isProfileUpdateNeeded`,对**刚拉不到 1 天**的 profile 会返回 false(节流)。心跳明明探测到面板侧有更新,结果被 1 天节流挡住,等于白跑。所以心跳调专用的 `syncProfilesFromPanelRevision`,内部**直接调 `updateProfile(applyUnchanged: false)`,绕过节流**。
  - **判断标志**:手动点"更新"按钮(走 `updateProfile` 不走节流)能拉到新订阅,心跳(走 `autoUpdateProfiles` 走节流)拉不到——就是这个问题。
  - **副作用**:`_isProfileUpdateNeeded` 的 `lastUpdate + autoUpdateDuration` 节流对心跳**不生效**,但对 24h 兜底定时器仍然生效,语义没变。

**rebase 注意点**：
- upstream 如果改 `_probePanelMe` / `_PanelMeProbe`,**保留 Gamebox 解析响应体的代码**（带 `[Gamebox]` 标记）
- upstream 如果改 `tickPanelSessionHeartbeat`,**保留 Gamebox 的 revision 同步代码块**
- upstream 如果改 `_PanelSession` / `_saveSession` / `_loadSession`,**保留 `lastSeenProfileRevision` 字段**
- upstream 如果改 `_loginLegacy` / `_login` 的返回值构造,**保留 Gamebox 的 `lastSeenProfileRevision` 赋值**

### 3.13 隐藏订阅入口（防止误操作配置）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 侧边栏隐藏"订阅"项 | `Navigation.getItems()` 里 `PageLabel.profiles` 对应的 `NavigationItem` 整段注释掉。侧边栏、悬浮面板（"more" 区域）、设置搜索项（`_buildSearchItems`）都从 `Navigation.getItems()` 派生,一次性全部消失 | `lib/common/navigation.dart` | `// [Gamebox] 隐藏订阅入口（防止用户误操作配置文件）` |

**为什么这么做**：
- 客户/用户通过侧边栏进入"订阅"页可以:重载当前订阅、删除订阅、添加新订阅 URL/文件、override 覆写 yaml 等。
- 这些操作**不是日常使用所必需**,反而是**误操作配置 yaml 的高风险路径**。
- 隐藏后,订阅的正常生命周期(登录时导入、心跳 60s 内静默同步、24h 兜底定时器、托盘退出保留 selectedMap,**§3.10 已支持**)全部不受影响。

**业务路径未受影响**：
- 登录时 `loginPanelAccount` → `_importSubscription` → 写入 Profile
- 心跳 `tickPanelSessionHeartbeat` → `autoUpdateProfiles` → 静默拉新
- 24h 定时器 `_autoUpdateProfilesTask` → 兜底
- 切换 `currentProfileId` → 仍可在底层使用,只是 UI 没入口

**rebase 注意点**：
- upstream 如果改 `Navigation.getItems()` 的 `NavigationItem` 列表结构,**保留 Gamebox 注释掉的 `PageLabel.profiles` 项**
- upstream 如果新增"订阅"类别的 `NavigationItem`(例如"备份与恢复"又被加回来等),按相同方式注释掉
- 不要删 `enum PageLabel.profiles` —— 业务代码(状态、`localizedName` 扩展)仍可能引用,只是 UI 入口不再出现

---

### 3.14 渲染后端固定 Skia(对齐 upstream v1.19.6)

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| `project.set_impeller_switch(...)` | `ImpellerSwitch::Disabled`(**无条件**,原 `#ifdef BETTBOX_COMPATIBLE_BUILD` 包块在 v1.19.6 被 upstream 删除) | `windows/runner/main.cpp` | `// [Gamebox] 对齐 upstream v1.19.6：无条件禁 Impeller` |
| `BETTBOX_COMPATIBLE_BUILD` cmake 注入块 | **整体删除**(原 `if("$ENV{BETTBOX_COMPATIBLE_BUILD}" STREQUAL "1")` 块) | `windows/runner/CMakeLists.txt` | `// [Gamebox] 对齐 upstream v1.19.6:移除 BETTBOX_COMPATIBLE_BUILD 兼容构建开关` |

**为什么这么做(用户问题)**:用户在虚拟机里对比 Gamebox 和 Bettbox 内存占用时发现:
- Gamebox 工作集 ~116 MB,Bettbox ~14.9 MB,差距 ~100 MB
- 物理机上几乎无差距
- 「不在虚拟机下没什么差距,1.19.5 之前没这个情况,新版才出现」

**根因**:
- Bettbox v1.19.5 → v1.19.6 把 `main.cpp` 中的 `set_impeller_switch(Disabled)` 从 `#ifdef BETTBOX_COMPATIBLE_BUILD` 改成**无条件**,意即「Bettbox v1.19.6 任何构建都禁 Impeller」
- Gamebox 同步 v1.19.6 时漏改 `main.cpp`,仍保留 v1.19.5 的 `#ifdef` 写法
- Gamebox 的 `package_windows.dart --compatible` **不传** `BETTBOX_COMPATIBLE_BUILD=1`(只有 `setup.dart --compatible` 才传)
- 结果:**Gamebox v1.19.6 portable build 实际 Impeller 启用**,Bettbox v1.19.6 portable build Impeller 强制关闭
- Impeller 在 Windows 虚拟 GPU(WDDM / DX12 软件回退 / Hyper-V virtual GPU)上,framebuffer + rasterization cache 常驻 ~80-120 MB 共享内存,正好对应 100 MB 差距
- v1.19.5 时 Gamebox 和 Bettbox 都是同样写法 + 同样的兼容性构建路径(setup.dart)→ 实际都禁 Impeller → 内存相近

**改动的副作用评估**:
- 物理机用户:Skia 软件渲染在「列表 + 表单」类 UI(本项目 99% 场景)上跟 Impeller 几乎无视觉差异
- 虚拟机用户:内存从 ~116 MB 降到 ~15 MB
- 心跳 / 60s group update / 24h profile update 等周期性任务更准时(不再因 virtual GPU stall 而被延迟几百 ms)
- 未来 rebase 不再因 main.cpp 写法不一致产生冲突

**rebase / sync 时**:
- upstream 如果进一步改 `main.cpp` 的 Impeller 配置(比如 Flutter 3.x 之后某天移除 Skia),**跟 upstream 走**
- upstream 如果重新加回 `BETTBOX_COMPATIBLE_BUILD` 相关 cmake 配置,**不跟**,Gamebox 仍保持无条件禁 Impeller

### 3.16 托盘退出通知面板下线（修在线设备不立即归零）

| 项 | 改前 | 改后 |
|---|---|---|
| `handleExit()` 通知面板下线 | **未调用 `_serverLogout`** → 直接 `system.exit()`,心跳停摆后面板要等会话过期才释放设备 | 在 `stopWakelockAutoRecovery()` 之后、`handleBackground()` 之前调 `await globalState.clearPanelSubscriptions?.call()` (即 `clearPanelDataOnExit`),它内部 `await _serverLogout(...)` POST `/api/v1/passport/auth/logout`(或回退 `/v1/auth/logout`),面板立即回收设备 |
| `logoutPanelAccount()` 登出路径 | `unawaited(_serverLogout(session.authData))` —— fire-and-forget,跟 `handleExit` 路径不一致 | 改为 `await globalState.clearPanelSubscriptions?.call()`,跟 `handleExit` 统一走同一条登出路径 |

**代码位置**:
- `lib/controller.dart` — `handleExit()` try 块内,新增 `await globalState.clearPanelSubscriptions?.call()` 包裹在 `try { } catch (_) {}` 里(登出失败不影响进程退出)
- `lib/panel/panel_auth.dart` — `logoutPanelAccount()` 把 `unawaited(_serverLogout(session.authData))` 一行替换成 `clearPanelSubscriptions` 包裹块

**为什么这么做(用户问题)**:
用户反馈「退出账号后面板上在线设备立即变成 0,而托盘退出后在线设备依然显示 1,再登录也不提示在线设备上限」。
- 退出账号走 `logoutPanelAccount()` → 调 `_serverLogout` POST `/api/v1/passport/auth/logout`(带 `Authorization: Bearer <authData>`) → 面板侧设备数立即减 → 显示 0
- 托盘退出走 `handleExit()` → **只**销毁托盘 / 停代理 / `clashCore.shutdown()` / `system.exit()`,**没有**任何登出 / 下线信号。心跳停止后,面板只能等会话过期(默认数小时)才回收设备,所以用户看到「仍显示 1」;此时再登录,面板侧认为旧会话还在,**不会再触发设备上限**
- 仓库里有个现成的 `clearPanelDataOnExit()`(`lib/panel/panel_auth.dart`),注释明确写着「进程退出前要等它完成,面板设备数才会减」,且在 `application.dart:126` 被注册到 `globalState.clearPanelSubscriptions`,**但 `handleExit` 里从来没被调用**

**修复方法**:
- `handleExit` 在 `stopWakelockAutoRecovery()` 之后显式 `await globalState.clearPanelSubscriptions?.call()`,让托盘退出和退出账号走同一条登出路径
- `logoutPanelAccount` 也改走 `clearPanelSubscriptions`,**两条出口共用一个函数**,避免再次走偏

**副作用评估**:
- 托盘退出多一次同步登出请求(6 秒超时,失败被 try/catch 吞掉),网络断开或面板服务暂时挂时不阻塞进程退出
- 之后再登录面板不再被「旧会话仍在线」挡住 → 设备上限提示恢复正常
- 无新增持久化字段、无新增 API,只是把现有未连接的路径接上

**rebase 注意点**:
- upstream 如果新增其它进程退出入口(`SIGTERM` 处理器 / `--exit` IPC / 「关闭」窗口按钮 等),**都应**调用 `globalState.clearPanelSubscriptions`,不要直接 `system.exit`
- upstream 如果重构 `_serverLogout` 或 `clearPanelDataOnExit`,**保留 `[Gamebox]` 标记和 `await` 语义**

---

### 3.17 显示文字全部从 Bettbox 改为 Gamebox + 删启动 splash + 登录页居中（2026-10-20）

把全 App 用户可见的 "Bettbox" 字样改成 "Gamebox",顺手清理 Android 12+ 启动 splash 显示的 "Bettbox" 字形矢量图、修正登录页(Center 居中 + 删右上角 _LoginWindowButtons 三个内置窗口按钮)。

| 项 | 改前 | 改后 |
|---|---|---|
| `AndroidManifest.xml` `android:label` | `"Bettbox"`（application + tile 各一处） | `"Gamebox"` |
| 4 个 `strings.xml` `bett_box` 字符串值 | `"Bettbox"`（values / zh-rCN / zh-rTW / ru） | `"Gamebox"`（包名 `com.appshub.bettbox.*` 保留不动,改动只覆盖显示） |
| VPN/服务/Toast 用户可见文字 | `setSession("Bettbox")`、`setContentTitle("Bettbox")`、3 个 channel 名 `"Bettbox Service" / ... High / ... Suspended`、2 个 Toast `"Bettbox Connected" / ... Suspended` | `setSession("Gamebox")`、`setContentTitle("Gamebox")`、channel 名 `"Gamebox ..."`、Toast 改 `"Gamebox ..."` |
| 渠道 ID `NOTIFICATION_CHANNEL` 等 | 保留 `"Bettbox"` / `"Bettbox_High"` / `"Bettbox_Suspended"` | **保持不变**（内部技术键,改会导致旧用户重装时 channel 无法复用,造成系统通知设置里出现两个渠道） |
| Android 12+ 启动 splash | `windowSplashScreenAnimatedIcon = @drawable/splash_text_light`（白底黑字"Bettbox"字形矢量图） | 删除该属性,splash 阶段只显示纯背景色（白/黑）→ 立刻交给 Flutter 接管 |
| `drawable/splash_text_light.xml`、`drawable/splash_text_dark.xml` | 引用方已删除 | 一并物理删除文件 |
| `PanelLoginGate` 布局 | `Stack + Positioned(置顶/最小化/关闭)`,`Padding(top:28)` 套表单 | `Stack(Column(顶 28px window drag \| Expanded(GestDetector for drag + Center + SingleChildScrollView 内填表单)) + Positioned(右上角 _LoginWindowButtons))`,登录卡在窗口内水平+垂直居中；**按钮保留但只在桌面端画** |
| `_LoginWindowButtons` widget | 3 个 IconButton(置顶/最小化/关闭)覆盖在登录卡右上角 | **保留并恢复**,但整体用 `system.isDesktop` 包住 —— 桌面端显示,Android/移动端不构建 |
| 登录页 window drag | 两处 `GestureDetector(onPanStart: startDragging)` 无条件调用 | 用同一个 `showWindowButtons` 条件化:移动端 `onPanStart: null`(见下方 2026-10-23 修正) |
| `lib/controller.dart` profile 默认名 | `profile?.label ?? 'Bettbox'` | 保留（无 fallback 时 fallback,非用户可见字符串） |
| Toast 用户可见 | `Bettbox Connected` / `Bettbox Suspended` | 已改为 `Gamebox Connected` / `Gamebox Suspended` |
| 包名 `com.appshub.bettbox.*`、类名 `BettboxService`/`BettboxVpnService`/`BettboxApplication`、window class `GAMEBOX_RUNNER_WIN32_WINDOW`、AUMID `Appshub.Gamebox`、URL scheme `bettbox://` | — | **未动**（这些都不是用户面向的显示文字,改包名是超大工程且要动签名/桌面快捷方式/卸载残留清理） |

**代码位置**:

- `android/app/src/main/AndroidManifest.xml` — application + tile label
- `android/app/src/main/res/values{,-v27,-night,-night-v27}/styles.xml` — 删除 `windowSplashScreenAnimatedIcon`
- `android/app/src/main/res/values{,-zh-rCN,-zh-rTW,-ru}/strings.xml` — `bett_box` 字符串值
- `android/app/src/main/kotlin/com/appshub/bettbox/services/BaseServiceInterface.kt` — `setContentTitle("Gamebox")` + 3 个 channel 显示名
- `android/app/src/main/kotlin/com/appshub/bettbox/services/BettboxVpnService.kt` — `setSession("Gamebox")`
- `android/app/src/main/kotlin/com/appshub/bettbox/plugins/VpnPlugin.kt` — 2 个 Toast 文案
- `lib/views/panel_login.dart` — `PanelLoginGate` 重构（Stack → Column + Center + 顶部 drag 条）；`_LoginWindowButtons` 类 + `_icon` helper 删除
- `android/app/src/main/res/drawable/splash_text_{light,dark}.xml` — 删除

**为什么这么做(用户问题)**:

1. **手机/桌面应用名 / 通知 / Toast 还是显示 "Bettbox"** —— 上游 `Bettbox` 是旧名,现在是 fork 项目叫 Gamebox,所有面向用户文字必须跟进
2. **打开应用瞬间有一闪而过的白底黑字 "Bettbox" 动画,再跳到登录界面** —— 这是 Android 12+ 的 SplashScreen 系统 API,读 `LaunchTheme` 的 `windowSplashScreenAnimatedIcon`,而该图标是两张矢量图(`splash_text_{light,dark}.xml`),`pathData` 是 "Bettbox" 字母的 vector outlines。Android 12 在主 Activity 起来前会强制 overlay 一段 splash,不显示就让 splash 完全消失
3. **Android 登录界面整体不居中,右上角有 「置顶/最小化/关闭」三个 Windows 风格按钮** —— `PanelLoginGate` 用 Stack + Positioned 把这三个 IconButton 浮在登录卡右上角;卡片本体被 `Padding(top:28)` 顶上去没有水平居中约束。把栈拆成 Column + Center,顶部留 28px 给 window drag,登录卡在窗口内居中显示

**⚠️ 2026-10-23 修正:上面的第 3 点只做了一半 —— Windows 的按钮被误删了**

- **原委**:为了消掉 Android 上那三个 Windows 风格按钮,把 `_LoginWindowButtons` 整个类删了,
  结果 **Windows 桌面端也跟着没了**置顶/最小化/关闭。用户反馈「安卓要隐藏、windows 要正常显示」。
- **现状**:`_LoginWindowButtons` 与 helper `_icon` **已恢复**(与删除前逐行一致),
  用 `system.isDesktop` 条件化渲染 —— `Positioned(top:0, right:0, child: _LoginWindowButtons())` 只在桌面端进树,
  Android 上整个 widget 不构建,自然不会有按钮。
- **同时修掉的隐患**:两处 `onPanStart: windowManager.startDragging()` 原来是无条件调用,
  而 `PanelLoginGate` 在 Android 上**也会渲染**(`application.dart` 的 `_AppHome` 只按 `panelUnlocked` 分支,不判平台),
  移动端调 `windowManager` 是无意义的。现已用同一个 `showWindowButtons` 条件化,移动端传 `onPanStart: null`。
- **以后改这块的规则**:**平台差异一律用 `system.isDesktop` / `system.isWindows` 就地条件化,
  不要用「删掉整个 widget」来隐藏某个平台的东西** —— 删了会连带影响其他平台。

**为什么 channel 名/ID 不一并改**:

- `setContentTitle("Bettbox")` 等渠道名(用户看到的)已改为 `Gamebox`,这部分是用户可见的
- `NOTIFICATION_CHANNEL = "Bettbox"` 这种是渠道 ID(技术键),Android 用来区分渠道;改 ID 后老用户重装时会出现两组渠道（一个旧 "Bettbox" 系统无法回收,一个 "Gamebox" 全新),反而给用户提示「两个 Gamebox」
- 用户原话「只改显示文字,包名可以不改」—— 渠道 ID 属于同类(技术键,不用户可见),保留稳

**为什么 splash 字形不重新画一个 "Gamebox" letterforms**:

- vector path 字母绘制要逐字描述坐标,7 个字符几百条 path 数据,手写字母 path 易误、易失真
- 用户口径就是「直接删除掉这个动画也可以,不需要」,所以走最简路线:删图标属性 + 删图标资源,splash 阶段只剩 0.x 秒背景色

**副作用评估**:

- 渠道 ID 保留,Android 11- 老用户重装通知设置里不会出现重复渠道;Android 12+ 渠道名 "Gamebox ..." 显示正常
- splash 阶段纯背景色 < 0.5 秒,Flutter 启动不会被明显拉长（系统 splash API 仍然在跑,只是不显示中央图标）
- 登录页按钮按平台条件化后,**Android 设备** 没影响（`system.isDesktop` 为 false,widget 不进树,拖动也置空）；**Windows/Linux** 上置顶/最小化/关闭三个按钮**照常显示**(2026-10-23 已恢复,此前被误删)
- 包名、签名、桌面快捷方式、注册表 key (`Software\\Gamebox`、`CSIDL_DESKTOPDIRECTORY` lnk) 路径都保留,升级是同一图标+签名,无需卸载（与 1.19.6 自身更新路径一致）

**rebase 注意点**:

- upstream 如果新增通知渠道（VPN / service / suspended）代码块,**保留 `[Gamebox]` 标记**,`setContentTitle` / 渠道显示名 / Toast 文案都得是 "Gamebox"
- upstream 如果调整 `PanelLoginGate` 布局,**保留 `system.isDesktop` 的条件化**(桌面端显示按钮 + 拖动,移动端都不启用),不要退回「删掉 `_LoginWindowButtons`」的做法
- upstream 如果启用 Android splash icon,**留空 `windowSplashScreenAnimatedIcon`** 或重新画图标,不要复用 `splash_text_light.xml`（上游也是把这 path 当字母 "Bettbox" 用的）
- upstream 如果改 strings.xml 的 `bett_box` key 名,新版顺手把 value 也对齐 "Gamebox"

---

### 3.18 安卓端首页默认卡片布局（v3.20 瀑布流最终版）

| 列 | 行号 | 改前（左图错版） | 改后（右图确认版） |
|---|---|---|---|
| 1 | 第 1 行（整行） | userProfile 放第 1 位（4 列宽，右侧空 4 列） | **networkSpeed** 放第 1 位（8 列宽，整行） |
| 2 | 第 2 行 | networkSpeed + trafficUsage | **trafficUsage + userProfile** |
| 3 | 第 3 行 | networkDetection + connectionsCount | **mediaUnlockSmall(连通性测试) + networkDetection** |
| 4 | 第 4 行 | memoryInfo（孤立） | **startButton + connectionsCount** |
| 5 | 第 5 行 | startButton（孤立） | **memoryInfo** |

3.18 期间出过两版错的，**最终版**是右图（你手动编辑的版本）：

```dart
const defaultAndroidDashboardWidgets = [
  networkSpeed,          // 8 列宽 → 第 1 行独占（最宽的卡片在最顶上）
  trafficUsage,          // ┐
  userProfile,           // ┘ 第 2 行 并排
  mediaUnlockSmall,      // ┐
  networkDetection,      // ┘ 第 3 行 并排（右边 networkDetection 比左矮，下方空位）
  startButton,           // ┐
  connectionsCount,      // ┘ 第 4 行 并排（connectionsCount 被挤到下一行左侧）
  memoryInfo,            // 第 5 行 整行
];
```

**瀑布流落位说明**：masonry 瀑布流（见 `widgets/grid.dart` 的 `_getOrigin`）每张卡落在当前 `dy` 最小的列上。`mediaUnlockSmall` 比 `networkDetection` 矮，右列下方会留空位；必须让矮的 `startButton` 紧跟在 `networkDetection` 后面去填那个空位，高一些的 `connectionsCount` 才会被挤到下一行左侧。

**为什么要重排（这次为啥左图错了）**：

mobile view 固定 8 列。`crossAxisCellCount: 8` 的卡片=整行独占，`crossAxisCellCount: 4`=半宽并排。在 8 列布局里：

- 把 `networkSpeed`（8 列）放第 1 位 → 它自己占满首行，下方正好是两两并排
- 把 `userProfile`（4 列）放第 1 位 → 它只占半行，右侧空 4 列，下一张也只占 4 列 → 整个页面"塌掉"，每行要么有空白要么被竖劈

所以「网络速度永远该在最顶」，这是这个 8 列布局的天然最优解。

**版本历史**：

| 版本 | 问题 |
|---|---|
| v3.18 之前 | 漏 userProfile |
| v3.18 第一版 | 把 userProfile 放首位，networkSpeed 被挤到第 2 行 |
| v3.19 第一版 | 第 3 行放反（memoryInfo \| networkDetection），漏 mediaUnlock |
| v3.20 第一/二版 | 以为左右对调即可，来回改了两遍 |
| **v3.20 最终版** | 瀑布流落位：mediaUnlockSmall → networkDetection → startButton → connectionsCount |

**代码位置**：

- `lib/models/config.dart` — `defaultAndroidDashboardWidgets` 最终版
- `lib/models/config.dart` — `legacyAndroidDefaultDashboardWidgets`（v3.18 之前漏 userProfile 的版本，作迁移比对用）
- `lib/models/config.dart` — `misplacedV3_18DashboardWidgets`（v3.18 第一次发版的错版，作迁移比对用，过几个版本后可删）
- `lib/models/config.dart` — `_isLegacyAndroidDefaultDashboard()` + `_isMisplacedV3_18Dashboard()`（双迁移分支）
- `lib/models/config.dart` — `AppSettingProps.safeFromJson` 里的 v3.20 注释更新

**为什么需要迁移逻辑（不只是改默认值）**：

`AppSettingProps.safeFromJson` 的 `@Default` **只在 JSON 里完全没有该字段时**生效。已安装用户的 `config.json` 里 `mobileDashboardWidgets` 已经有值，所以**光改 `defaultAndroidDashboardWidgets` 对老用户无效**，他们的首页还是旧排版。

因此加了一条迁移：仅当 `system.isAndroid` 且读回来的 `mobileDashboardWidgets` **等于**以下任一列表时，才认定为「用户从未手动编辑过首页」并覆盖成最终版：

1. `legacyAndroidDefaultDashboardWidgets`（v3.18 之前漏 userProfile 的版本） — 用**集合匹配**，即这 6 张卡片都在、乱序也算动过
2. `misplacedV3_18DashboardWidgets`（v3.18 第一次发版的错版） — 用**精确顺序匹配**，因为这是 v3.18 自家版本，乱序的可能性低

只要用户动过顺序、或增删过任何卡片（增删常用卡片会让长度或内容偏离该列表），就原样保留，**不覆盖用户自己的布局**。

迁移是一次性的：迁移后写入的 `config.json` 里就是最终版，下次启动不会再命中迁移分支，不会反复覆盖。

> **v3.20 行为说明**：v3.20 **不按「元素集合相同」强制刷新顺序**。瀑布流的实际落位由卡片高度决定，用户装新包就会拿到新默认值，无需覆盖持久化里的顺序（会破坏用户手动排的版）。

---

### 3.19 安卓端默认开关调整（4 项，2026-10-20）

| # | 设置 | UI 路径 | 全局默认 | 安卓默认 | 实际行为说明 |
|---|---|---|---|---|---|
| 1 | **查找进程** | 内核配置 → 常规 → 查找进程 | `FindProcessMode.off`（关） | `off`（关） | `ClashConfig.findProcessMode`。Android 端 `state.dart` 原来硬编码 `always`（绕过 `@Default`），已改为统一走 `defaultClashConfig` |
| 2 | **网络变化时清理 DNS** | 增强工具 → 常规 → 网络变化时清理 DNS | `false` | **`true`** | `AppSettingProps.flushDnsOnNetworkChange`。网络切换时自动 `clashCore.flushDnsCache()`。桌面端字段写 true 不影响（实现里有 `system.isAndroid` 门禁） |
| 3 | **网速通知** | 增强工具 → 常规 → 网速通知 | `false` | **`true`** | `VpnProps.networkSpeedNotification`。锁屏 / 前台时把网速切到系统通知。桌面端字段写 true 不影响（同上） |
| 4 | **休眠支持** | 增强工具 → 常规 → 休眠支持 | `true` | **`false`** | `VpnProps.dozeSuspend`。控制是否跟随 Android Doze 模式把流量挂起。详见 3.19 子节「休眠支持说明」 |

> **补充说明**：
> - **回环保护**：`VpnProps.loopbackProtection` 全局默认 `@Default(true)`，跟随上游，不应默认关闭（已在 2026-10-20 还原）
> - **高优先级**：`VpnProps.highPriorityNotification` 全局默认 `@Default(true)`，跟随上游
> - **快速响应**：`VpnProps.quickResponse` 全局默认 `@Default(true)`，跟随上游

**代码位置**：

- `lib/models/clash_config.dart` — `ClashConfig.safeFormJson` 异常路径兜底改用 `defaultClashConfig`（与 `@Default` 对齐）
- `lib/state.dart` — `globalState.config` getter 和 `AppState.init()` 里的 `patchClashConfig` 构造，Android 不再硬编码 `always`，改为统一走 `defaultClashConfig`
- `lib/models/config.dart` — `VpnProps.safeFromJson` 安卓专用默认值（`networkSpeedNotification=true`、`dozeSuspend=false`）
- `lib/models/config.dart` — `AppSettingProps.safeFromJson` 安卓专用默认值（`flushDnsOnNetworkChange=true`）
- 同文件同函数，顺便把 `AppSettingProps.safeFromJson` 里的两个 `if (system.isAndroid)` 相邻分支合并成一个

#### 「休眠支持」说明（`dozeSuspend`）

它在 `android/app/src/main/kotlin/com/appshub/bettbox/modules/SuspendModule.kt` 这个 Kotlin 模块里干活，只在 Android 上生效：

- **开启时**：注册监听 `SCREEN_ON` / `SCREEN_OFF` / `USER_PRESENT` / `DEVICE_IDLE_MODE_CHANGED` 4 个系统事件；当系统进入 Doze（屏幕关闭 + 设备空闲）时延迟 3 秒，调用 `Core.dozeSuspend(true)` 把当前连接挂起、降低流量；唤醒时立即恢复
- **关闭时**：注册/反注册都跳过

**用户取舍**：

- 大多数普通用户：保持开启（默认 true），续航更好
- 长期挂着代理做下载、跑脚本、做爬虫：关闭，避免 Doze 把流量挂起、任务中断

3.19 把安卓默认值从 `true` 改为 `false`，更倾向「不打断长任务」。用户仍然可以在「增强工具 → 常规 → 休眠支持」开关里手动改回 true。

**为什么是「Android 专用默认」而不是全局改字段默认值**：

- 这三个开关的全局 `@Default` 都是上游定的（`@Default(false) flushDnsOnNetworkChange`、`@Default(false) networkSpeedNotification`、`@Default(true) dozeSuspend`）
- 桌面端读这些字段的程序都有 `system.isAndroid &&` 包裹（`controller.dart` / `state.dart`），即使字段写 `true` / `false` 也不会真的触发别的行为
- 全局改 `@Default` 会污染 Windows / macOS / Linux 三端用户的体验（万一哪天 upstream 在桌面端加了新逻辑，会让这些端莫名其妙就启用）
- 「Android 专用默认 + 桌面端保留上游默认」改动最小、最可控

**生效路径**：

- 改动放在 `*.safeFromJson` 的 `json == null` 分支里 → 只有**全新安装**（`appSetting` / `vpnProps` 整个对象在 config.json 里都不存在）才用 Android 专用默认值
- **老用户升级**（config.json 里已经有 appSetting / vpnProps）→ 原值保留，不会被这次改动覆盖
- 想覆盖老用户的话，需要把单个字段单独提出来做识别（类似 3.18 dashboard 迁移「legacy 默认 → 新默认」），3.19 暂不做

**副作用评估**：

- 全新安卓安装：开箱即用获得游戏/长任务的合理默认值（清理 DNS ✓ / 网速通知 ✓ / 不被 Doze 打断 ✓）
- 升级到 3.19 的老安卓用户：3 个开关在「增强工具 → 常规」里**不会自动变成新默认**，用户仍看到 3.18 之前的旧值
- 桌面端：完全无变化（`@Default` 和字段逻辑都没动）

**rebase 注意点**：

- upstream 改了 `VpnProps` 默认值（任何字段），都要重新核对 `VpnProps.safeFromJson` 里 `defaultVpnProps.copyWith(...)` 跟上游是否对齐（防止漏新字段）
- upstream 给 `clash_config.dart` 加了新的 `FindProcessMode` 值，也要核对 `safeFormJson` 的兜底分支行为
- 4 个开关的 Android 专用默认都是「用户偏好」，将来想改回上游默认值时，把这段 `if (system.isAndroid)` 条件删掉即可

---

### 3.20 同步上游 v1.19.7 的冲突处理记录（2026-10-23）

本次把 `origin/main`（v1.19.7, commit `1fb8806f`）merge 进 `gamebox`，merge commit = `337ea70f`。
**22 个文件报冲突，但只有 13 处是真实冲突** —— 详见下面的分类表。

#### ⚠ 关键教训：`.gitattributes` 存在之前提交的文件带 CRLF，会让整文件冲突

| 现象 | 根因 |
|---|---|
| `arb/*.arb`(6)、`lib/application.dart`、`lib/state.dart`、`lib/views/tools.dart`、`lib/widgets/list.dart`、`pubspec.lock` 等 **整文件** 变成冲突块（`<<<<<<<` 在第 1 行、`=======` 在中间、`>>>>>>>` 在最后一行）| Gamebox 早期提交时这些 blob 存的是 **CRLF**，`.gitattributes` 的 `* text=auto eol=lf` 是**后来**才加的，老 blob 没重新规范化。upstream 是 LF。git 逐字节 diff 认为「全不一样」，于是整个文件都成了冲突 |

**处理方法（下次同步上游照做）**：
1. 不要手工解 22 个文件 —— 先把三方版本（`:1:` base / `:2:` ours / `:3:` theirs）取出来做 **EOL 归一化**（CRLF/CR → LF），
2. 再跑真正的三方合并（`git merge-file -p base ours theirs`），
3. 只有剩下的冲突块才是**真实语义冲突**，数量通常是个位数。

> 建议：以后新增/修改文件前确认 `.gitattributes` 生效；已入库的老 CRLF 文件如果想彻底干净，
> 可以单独提一个「EOL 归一化」commit（只改行尾符、不改内容），之后同步上游就不会再整文件冲突。

#### 本次真实冲突逐项决策（13 处）

| 文件 | 冲突内容 | 决策 | 理由 |
|---|---|---|---|
| `lib/controller.dart` | Gamebox 硬编码英文 `'TUN mode requires administrator privileges.'` vs upstream 的 `appLocalizations.tunEnableRequireAdmin` + portable 重启按钮 | **跟上游** | Gamebox 那行没有 `[Gamebox]` 标记、也不在本文件清单里，属于早期本地顺手改的；upstream 版本已 i18n 化，且新增的 arb key 已经同步进来，跟上游才对 |
| `lib/models/config.dart` | ① Gamebox 的 `userProfile` 补位逻辑 vs upstream 新增的 `defaultSidebarFlyoutEntries` / `sidebarFlyoutEntriesSafeFromJson` | **两边都留** | 上游是在同一位置**新增**函数，不是替换；Gamebox 的补位逻辑要保留，upstream 的新函数也要留 |
| `lib/models/config.dart` | ② Gamebox `@Default(true) enableHighPriority` vs upstream 新增 `@Default('') backupPassword` + `enableHighPriority` | **两边都留**：保留上游新字段 `backupPassword`，但 `enableHighPriority` 维持 Gamebox 的 `true` | 上游备份功能新增字段（Gamebox 只隐藏入口、不删数据结构，见 §3.2）；高优先级是 Gamebox 明确的开源默认（§3.4）|
| `lib/views/dashboard/widgets/outbound_mode.dart` | Gamebox 的 throw stub vs upstream 完整的 `_OutboundModeButton` / `_OutboundStatusChips` 实现 | **保留 Gamebox stub** | §3.7 规定永久删除出站模式卡片。上游实现依赖 `Mode` enum + 一堆 provider，留着是死代码 |
| `lib/widgets/list.dart` | Gamebox 给 `CommonCard` 传 `textColor` vs upstream 把内联 Column 抽成 `content` 变量 | **两边都留**：`child: content` + 保留 `textColor:` | 上游是纯重构（行为不变），Gamebox 的 `textColor` 是额外能力，`CommonCard` 本来就有这个参数 |
| `setup.dart` | Gamebox 漏了 `await` + 传 `compatible:` vs upstream 补上 `await` 且不传 `compatible` | **取上游的 `await` + 保留 `compatible:`** | `await` 是上游修的真 bug（macOS dmg 可能没打好就退出）；`compatible` 在 macOS 分支恒为 `false`（`execute()` 已限制 `--compatible` 只对 windows/linux 生效），传不传行为一致 |
| `windows/packaging/exe/package_windows.dart` | ① core/helper 可执行名、服务名、管道名、计划任务名 ② `PUBLISHER_URL` / `INSTALL_DIR_NAME` ③ portable zip 文件名 | **全部保留 Gamebox 的 `$productName` / `$displayName` 参数化写法** | §3.6 要求全局 Bettbox→Gamebox；Gamebox 写法还更好：上游硬编码 `'Bettbox'` 字符串，Gamebox 用 `make_config.yaml` 的值派生，改一处就够 |

#### ⚠ 额外抓到的「静默合并」坑（git 没报冲突但会编译不过）

`lib/enum/enum.dart` 上游 v1.19.7 **又加回了**对已被 Gamebox 删除的 `outboundMode` / `outboundModeV2` 枚举值的引用：

```dart
// 上游加回的 3 处，Gamebox 必须剔除（否则 undefined_enum_constant 编译错误）
static const _variantGroups = [ ..., [outboundModeV2, outboundMode], ... ];
DashboardTileSize get nativeSize => switch (this) {
  outboundModeV2 => DashboardTileSize.wide,          // ← 删
  outboundMode || mediaUnlockSmall || ... => ...,   // ← outboundMode || 删掉
};
```

这几行落在 Gamebox 没改过的上下文里，git 认为「自动合并成功」，**但引用的枚举值不存在**。
只有 `flutter analyze` 才能抓到 —— 所以每次同步上游后**必须**跑一次 `flutter analyze`（§8）。

连带修的两个上游新测试（它们断言了被 Gamebox 删除的枚举值）：
- `test/views/dashboard_tile_test.dart` → 改用 `DashboardWidget.trafficUsage` 验证 tall 尺寸
- `test/widgets/editable_grid_test.dart` → 改用 `mediaUnlockSmall.family` 验证归并逻辑

#### 生成代码不要手工解冲突

`lib/models/generated/{clash_config,config}.{freezed.dart,g.dart}` 这 4 个文件的冲突**全部由源文件自动决定**，
手工解容易和 `build_runner` 的输出不一致。正确做法：

```bash
flutter pub get
dart run build_runner build          # 注意：新版已移除 --delete-conflicting-outputs
flutter analyze --no-pub
```

`build_runner` 会同时吃到：Gamebox 的默认值（`tun.enable=true`、`disableIcmpForwarding=false`、`enableHighPriority=true`、`disclaimerAccepted=true`）
和上游新加的字段（`Tun.dnsMode`、`AppSettingProps.backupPassword`），不需要手工取舍。

#### 本次验证结果

| 项 | 结果 |
|---|---|
| `git diff --diff-filter=U` | 0（无未解决冲突） |
| **`core/` vs 上游** | **完全一致（1096 文件逐字节相同）→ 内核已同步到 v1.19.33** |
| `flutter analyze` | **0 error**（4 warning 是合并前就有的：`window.dart` 未用 import/变量、`controller.dart` 重复 import/未用变量）|
| `flutter test` | 15 failing（合并**前**同分支是 28 failing → 上游顺带修好了 13 个，本次无新增失败）|
| `[Gamebox]` 标记总数 | 225 |
| 42 项定制逐项比对（合并前 vs 合并后）| **38 项 INTACT，0 项 LOST** |

#### 内核同步核对（Mihomo v1.19.33）

Gamebox 对 `core/` **零定制** —— 内核是 in-tree vendored（仓库无 `.gitmodules`，`core/Clash.Meta` 也不是独立 git 仓库），
所以"内核有没有更新"完全取决于上游那 1096 个文件的树有没有被完整带过来。

| 核对点 | 结果 |
|---|---|
| `git diff HEAD upstream/main -- core/` | **空**（逐字节一致）|
| 文件数 | 1096 = 1096 ✅ |
| `core/Clash.Meta/go.mod` | 与上游一致 ✅ |
| v1.19.33 新特性抽查 | TUN `dns-mode`（`TunDnsMode`）✅；`core/toolbox/` 全套 iPerf3/STUN/speedtest/route-trace 端点 ✅ |

> ⚠️ **内核版本号在源码里查不到**：`core/Clash.Meta/constant/version.go` 是 `Version = ""`，
> 真正的版本号在构建时通过 `-ldflags` 注入（`setup.dart` 的 `buildCore`）。
> 想确认"跑起来的是不是 v1.19.33"，要么比对 `core/` 整棵树，要么看运行时的内核版本输出。

#### v1.19.7 更新日志逐条核对

| 上游 changelog | 是否同步 | 依据 |
|---|---|---|
| 多端网络调试工具（iPerf3/STUN/speedtest/route-trace/age/DNS 查询/MRS）| ✅ | `core/toolbox/*.go` 12 个端点 + `lib/pages/toolbox/` 9 个页面 + `lib/views/toolbox.dart` |
| WebDAV 自动备份 + 备份密码 AES | ✅ | `lib/views/backup_and_recovery.dart` + `AppSettingProps.backupPassword`（**字段保留，入口按 §3.2 隐藏**）|
| 请求页与连接页合并 | ✅ | `lib/views/connection/requests.dart` 已删除 |
| 流媒体解锁批量节点检测 | ✅ | `lib/common/media_unlock_checker.dart` + `lib/pages/media_unlock.dart` |
| 首页/工具箱无界水印大图标 | ✅ | `lib/views/toolbox.dart` |
| Android 莫奈取色（12+）| ✅ | `lib/state.dart:_initDynamicColor()` → `DynamicColorPlugin.getCorePalette()` / `MaterialDynamicColors` |
| 配置覆写逻辑优化 | ✅ | `lib/views/profiles/override_profile.dart` |
| macOS Dock 图标与窗口同步 | ✅ | `macos/Runner/AppDelegate.swift` + `lib/manager/window_manager.dart` |
| Windows 便携版目录改进 | ✅ | `windows/packaging/exe/package_windows.dart` + `lib/common/path.dart` |
| Linux 自动 DNS 管理修复 | ✅ | `lib/state.dart` 的 DNS 相关逻辑与上游**逐字节一致**（diff 为空）|
| 桌面端内核断开自动重启 | ✅ | `lib/controller.dart` + `lib/state.dart` |
| 编辑器语法高亮/折叠/搜索性能 | ✅ | `plugins/code_forge/rust/src/editor/{highlight,folds,search}.rs` |
| 修复渲染引擎引起的桌面端兼容问题 | ✅ | 与 §3.14「Impeller 无条件禁」同向 —— 该项已按 v1.19.6/v1.19.7 上游写法无条件禁用 |
| **新 Slogan "Better Network Toolbox"** | ⚠️ **仅文档，非 App UI** | 只存在于 `README.md` / `readme/README_*.md`。`readme/` 6 个语言文件与上游逐字节一致；根 `README.md` 因上游更新而被带入，仍写 "Bettbox"。**App 内没有任何 slogan 文案**，所以对用户无影响。按用户决定：**README 保持和上游一致，不改** |

#### 用户可见 "Bettbox" 文案清理 ✅ 已完成

跑全仓品牌审计（排除注释 / 包名 / URL / 技术标识符 / channel ID 之后）找出 3 处用户能看到 "Bettbox"，
已逐个比对确认**合并前后完全相同**（上游原样如此，**不是合并弄丢的**），本次已全部改成 Gamebox：

| 位置 | 改动 |
|---|---|
| `arb/intl_*.arb`（7 语言 ×2 条）| `iperfScanHint` / `iperfFirewallTip` → Gamebox，并跑了 `dart run intl_utils:generate` 同步 `lib/l10n/` |
| `lib/views/profiles/tv_qr_import_dialog.dart` | 4 处：`<title>`、`<h1>📺 </h1>`、zh `title`、en `title` |
| `lib/main.dart:257` | `profile?.label ?? 'Bettbox'` → 仍保留（仅 profile 无 label 时的网速通知兜底名，正常路径不可见；改了反而和历史通知不一致）|

> ⚠️ `localStorage` 的 key `'bettbox_tv_lang'` **故意不改** —— 改了老用户 TV 端语言偏好会丢失，属技术标识符。

剩余 `Bettbox`/`bettbox` 全部是**技术标识符，不该改**：
包名 `com.appshub.bettbox.*`、URL scheme `bettbox://`、通知渠道 ID `Bettbox`/`Bettbox_High`/`Bettbox_Suspended`、
Unix socket 名、polkit 规则文件名、salt、`BettboxCore.exe` 二进制名、`distribute_options.yaml`（Linux deb/rpm 打包用）、
测试临时文件名。见 §3.17「为什么 channel 名/ID 不一并改」。

#### 内核是怎么来的（不是复制上游便携版）

**内核不是从上游便携版里"复制"来的，而是每次打包时用 Go 从 `core/` 源码树现场编译出来的。**

| 环节 | 说明 |
|---|---|
| 源码来源 | `core/`（内含 vendored 的 `core/Clash.Meta`），随仓库一起 merge，**不是 submodule、不联网下载** |
| 编译时机 | 打包时 `setup.dart` 调 `Build.buildCore()` → `go build`（`-tags` / `-trimpath` / `-ldflags`），产物落到 `libclash/<target>/<arch>/` |
| 命名 | `Build.coreName = '${identityName}Core'` —— 靠 `AppIdentity` 参数化成 **`GameboxCore`**（上游是 `BettboxCore`），见 §3.16 |
| 进包 | 桌面端 `appPath.bundledCorePath` 从可执行文件同目录取 `${coreExecutableName}.exe`；Linux AppImage 走 `ensureAppImageCoreSynced()` 拷到外部目录（带 `.core_stamp` 做 mtime/size 戳）|
| 启动 | `lib/clash/service.dart` 用 `Process.start(appPath.corePath, ...)` 起**独立进程**（Windows 走 helper 服务的 `startCore`）；移动端才用 FFI `libmeta.so` |
| 版本号 | 构建时 `-ldflags` 注入，源码里查不到（见上文 core 核对说明）|

> 所以"内核是否同步到 v1.19.33"取决于**仓库里 `core/` 源码是否与上游一致**，
> 只要 `git diff HEAD upstream/main -- core/` 为空，打出来的 `GameboxCore.exe` 就是 v1.19.33。
> 反过来说，**不要从任何地方单独拷一个 `*Core.exe` 进仓库** —— 那会绕过源码、绕过 `-ldflags`、也过不了 §3.16 的命名检查。

---

## 4. 关于页特殊处理

`lib/views/about.dart` 是**用户偏好版本**（不是上游 v1.19.5 默认）,**rebase 时不要用 upstream/main 的 about.dart 覆盖**。

**重要**:rebase 之前先把本文件加一行 `// [Gamebox] do not rebase` 标记到 `lib/views/about.dart` 顶部,避免误操作。

---

## 5. 资源文件

### 5.1 头像

`assets/images/avatars/mouren1988.jpg` —— GitHub 仓库维护者头像,本地打包到安装包。

**二进制写入注意事项**：
- PowerShell `Set-Content` 会编码破坏 PNG/JPG 字节
- 必须用 `[System.IO.File]::WriteAllBytes()` 写入
- 写入后用 `git diff --stat` 确认是 `Bin ... -> ... bytes` 而不是文本 diff

### 5.2 图标 / 启动图

`assets/manual/app-icon.ico` 等二进制资源同理。

---

## 6. 注释规范

所有 Gamebox 定制代码必须带 `// [Gamebox]` 注释:

```dart
// [Gamebox] 说明
final value = somethingModified;

// [Gamebox] 第二行说明
// 上游默认值是 xxx,Gamebox 改为 yyy,理由是 zzz
```

**rebase 时如果遇到 `<<<<<<<` 冲突,Gamebox 那一段****总是****带 [Gamebox] 标记**——保留它。

---

## 7. 提交规范

Commit message 格式:

```
Gamebox: <一句话说明>

- <改动 1 文件>：<说明>
- <改动 2 文件>：<说明>
- ...

同步上游命令：git fetch upstream && git rebase upstream/main
```

**注意**:不要在 commit message 里说「同步上游」 —— 同步上游本身是**操作流程**,不是**commit 内容**。Gamebox 上的 commit 应该只是 Gamebox 自己的改动。

---

## 8. 打包 / 发布 / 测试

### 8.1 打包命令

```bash
# 在 gamebox 分支上
cd D:\iGame+\Gamebox
git checkout gamebox

# 只打 installer（最常用）
dart run windows/packaging/exe/package_windows.dart --arch amd64
# 产物: dist/Gamebox-{version}-windows-amd64-setup.exe

# installer + portable
dart run windows/packaging/exe/package_windows.dart --arch amd64 --compatible
# 产物: installer + dist/Gamebox-{version}-windows-amd64-compatible-portable.zip

# 只 portable（不上 installer）
dart run windows/packaging/exe/package_windows.dart --arch amd64 --compatible --installer=false
```

**注意**:`--arch amd64` 是必填,`--compatible` 默认关闭 portable（要 portable 需显式加）。

### 8.2 flutter build 前置

打包脚本**假定** `build/windows/x64/runner/Release/` 已有内容,即已经 `flutter build` 过:

```bash
# 标准 build
flutter build windows --release --dart-define=APP_ENV=stable

# 仅 build（不 run）
flutter build windows --release --dart-define=APP_ENV=stable --no-pub
```

### 8.3 验证清单（打包后必查）

1. 冷启动看到登录小窗（`PanelLoginGate`）
2. 冷启动小窗右上角有「置顶/最小化/关闭」三个按钮（桌面端），
   点 X 能彻底退出（不留 gamebox + clash 内核残留进程）
2b. 顶部 28px 区域可拖动窗口；安卓端这三个按钮与拖动都不出现
2. 登录后看到首页（`HomePage`）
3. 侧边栏/悬浮面板**没有**「备份与恢复」入口
4. 设置 → 关于页是 **Gamebox** 而不是 Bettbox
5. 8 项定制默认值（深色/中文/UA 等）符合 §3 预期
6. 任务管理器看进程名是 `Gamebox.exe` 不是 `Bettbox.exe`
7. 安装路径是 `C:\Program Files\Gamebox` 不是 `C:\Program Files\Bettbox`
8. 控制面板卸载列表是 `Gamebox`

### 8.4 发布流程

```bash
# 1. 在 gamebox 分支上 bump version
#    编辑 pubspec.yaml: version: 1.19.7+2026102001
#    编辑 version.json: { "version": "1.19.7+2026102001", "notes": "v1.19.7" }

# 2. commit
git add pubspec.yaml version.json
git commit -m "Gamebox: bump version to 1.19.7"

# 3. push
git push origin gamebox

# 4. 打包
flutter build windows --release --dart-define=APP_ENV=stable
dart run windows/packaging/exe/package_windows.dart --arch amd64 --compatible

# 5. 上传蓝奏云
#    - Gamebox-{version}-windows-amd64-setup.exe
#    - Gamebox-{version}-windows-amd64-compatible-portable.zip

# 6. 验证 version.json 同步(notes 跟 version 一致)
#    访问 https://raw.githubusercontent.com/mouren1988/Bettbox/refs/heads/gamebox/version.json
```

### 8.5 测试

```bash
# 编译
flutter build windows --release --dart-define=APP_ENV=stable

# 启动
.\build\windows\x64\runner\Release\Gamebox.exe

# 验证项
# 1. 冷启动看到登录小窗（PanelLoginGate）
# 1b. 右上角「置顶/最小化/关闭」三个按钮在（桌面端）；点 X 进程彻底退出
# 2. 登录后看到首页（HomePage）
# 3. 侧边栏/悬浮面板没有"备份与恢复"入口
# 4. 设置 → 关于页是 Gamebox 而不是 Bettbox
# 5. 8 项定制默认值（深色/中文/UA 等）符合预期
```

---

## 9. 紧急回滚（force push 撤销）

**只在 gamebox 上做**,**绝不在 main 上**。

```bash
# 1. 看 gamebox 推送历史
git reflog show origin/gamebox

# 2. 找到要回滚到的 commit
git reset --hard <commit-hash>

# 3. force push
git push --force-with-lease origin gamebox

# 4. 验证
git fetch origin
git rev-parse origin/gamebox
```

**注意**:`--force-with-lease` 比 `--force` 安全（会检查远端是否是你预期的状态,防止覆盖别人）。
