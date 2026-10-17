# Gamebox 定制化修改清单

> 本文件记录 Gamebox 相对 upstream Bettbox 的所有定制化修改。
> 任何修改都要带 `// [Gamebox]` 注释，并同步更新本文件。

**当前 gamebox 分支 HEAD：`d59138b1`**（以 `https://github.com/mouren1988/Bettbox.git gamebox` 为准）

**`d59138b1`（最近推送的 GB/TB 自动切换提交，未推改动见下面 §1.9、§7）**：
- 上一波提交（按时间倒序）：
  1. `d59138b1` — traffic 用量显示 GB→TB 自动切换（>=1024 GB 用 TB 单位，避免数字过长）
  2. `dcbea701` — 用户卡图标 24px + padding 平衡
  3. `2d7425d2` — 用户卡 title 改用 person_outline（与 IP 卡风格一致）
  4. `eaa017e5` — 用户卡用面板账号名 + 删除冗余「用户:」行（保持 3 行布局）

**本轮未推送的「即将 commit」改动**（按主题归类，见 §1.9 / §7）：

| 主题 | 文件 | 说明 |
|---|---|---|
| i18n 锁 zh_CN | `lib/views/tools.dart` `_LocaleItem` | Radio 列表只显示简体中文一项；老 appSetting.locale 不擦（兼容） |
| 卡片样式微调 | `lib/widgets/card.dart` `lib/widgets/list.dart` | i18n 锁 zh_CN 同步 |
| 关于页描述 | `lib/l10n/intl/messages_zh_CN.dart` | desc 缩短为「致力于更好的客户端体验。」；otherContributors 改名 |
| ARB 同步 | `arb/intl_*.arb`（6 个 locale） | otherContributors 翻译同步；otherContributors 中文去「(随机排序)」 |
| intl_utils 重生成 | `lib/controller.dart` `lib/models/clash_config.dart` `lib/views/about.dart` `lib/views/dashboard/widgets/widgets.dart` | intl_utils 自动重生成 + [Gamebox] 注释保留 |
| 安装器去英文 | `windows/packaging/exe/inno_setup.iss` `windows/packaging/exe/make_config.yaml` | 去掉 english locale + english CustomMessages，避免 ISCC 报 Unknown language |
| 辅助脚本 | `tools/fix_encoding.dart` `tools/write_make_config.dart` | 修复 arb 编码 + 写入 make_config 的工具脚本 |

---

## 0. 同步上游 SOP（重要）

```bash
# 1. 拉取上游最新代码
git fetch upstream

# 2. 切到 main 分支（同步专用）
git checkout main
git merge upstream/main

# 3. 切回 gamebox 分支，rebase
git checkout gamebox
git rebase main

# 4. 解决冲突时优先保留本文件列出的所有修改
#    冲突标记里如果 upstream 删了 Gamebox 定制代码，**保留** Gamebox 那一段。

# 5. 按本文件第三章检查清单逐项核对

# 6. 重新构建
flutter build windows --release --dart-define=APP_ENV=stable
```

**冲突优先级**：
- `[Gamebox]` 标记的代码 **永远优先保留**
- 上游新增的同位置代码，**用注释保留上游版本 + Gamebox 自己的版本**（参考 `lib/views/tools.dart` 的备份恢复处理方式）
- 上游删除的 Gamebox 依赖的代码，**手动重新移植**（参考 `lib/state.dart` 的 `openUserManual`）

---

## 1. 定制化项清单

### 1.1 默认深色主题 + 简体中文固定

| 项 | 默认值 | 文件 | 行号（ac313cce） | 注释 |
|---|---|---|---|---|
| themeMode | `dark` | `lib/models/config.dart` | `themeMode` 字段 | `// [Gamebox] 默认深色主题` |
| locale | 固定 `zh-CN` | `lib/application.dart` `lib/state.dart` | `MaterialApp.locale` | `// [Gamebox] 固定简体中文` |

### 1.2 备份与恢复隐藏

| 项 | 状态 | 文件 | 说明 |
|---|---|---|---|
| 侧边栏 `backupAndRecovery` | **隐藏** | `lib/views/tools.dart:124` | `// [Gamebox] 隐藏备份与恢复` |
| 悬浮面板 `Backup` 入口 | **隐藏** | `lib/widgets/floating_panel.dart`（新 architecture 才有） | `// [Gamebox] 隐藏备份` |

**rebase 时如果 upstream 新增了备份入口，按相同方式注释掉 + 加 [Gamebox] 注释。**

### 1.3 内核配置默认值

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| 连通性测试 URL | `https://cf.cloudflare.com/...` | `lib/models/clash_config.dart` | `// [Gamebox] 默认 CF 测试链接` |
| 查找进程 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 查找进程默认开启` |
| 外部控制 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 外部控制默认开启` |
| 控制密码 | **空** | `lib/models/clash_config.dart` | `// [Gamebox] 控制密码为空` |
| 全局 User-Agent | `Gamebox`（无版本号；上游 Bettbox 是 `clash.meta`，本项目刻意不带版本号） | `lib/models/clash_config.dart` | `// [Gamebox] UA 默认 Gamebox（不带版本号）` |
| BundleMRS.7z URL | `https://v4.gh-proxy.org/https://github.com/appshubcc/bett-rules/releases/download/latest/BundleMRS.7z`（上游是 GitHub 直连） | `lib/views/resources.dart` | `// [Gamebox] BundleMRS.7z via gh-proxy mirror` |
| GEO 默认 URL（生成器） | 3 条全部加 `https://v4.gh-proxy.org/` 前缀：`mmdb` / `asn` / `geosite`（`lib/models/generated/clash_config.g.dart:_GeoXUrlFromJson`） | `lib/models/generated/clash_config.g.dart` | `// [Gamebox] Mirrors of GitHub releases via v4.gh-proxy.org` |
| GEO 默认 URL（源码） | 同上，3 条 `@Default()` 全部加 `https://v4.gh-proxy.org/` 前缀（`lib/models/clash_config.dart:GeoXUrl`） | `lib/models/clash_config.dart` | `// [Gamebox] GeoXUrl default URLs` |
| 虚拟网卡 | **开启（桌面端）** | `lib/models/clash_config.dart` | `// [Gamebox] 桌面端默认开启虚拟网卡` |
| 系统代理 | **关闭** | `lib/models/clash_config.dart` | `// [Gamebox] 系统代理默认关闭` |
| ICMP 转发 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] ICMP 转发默认开启` |
| TUN 模式（Windows） | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] TUN 默认开启` |

### 1.4 增强工具

| 项 | 默认值 | 文件 | 注释 |
|---|---|---|---|
| 托盘增强 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 托盘增强开启` |
| 隐藏托盘菜单 | 规则 / 全局 / 直连 **隐藏** | `lib/common/tray.dart` | `// [Gamebox] 托盘菜单隐藏规则、全局、直连` |
| 高优先级 | **开启** | `lib/models/clash_config.dart` | `// [Gamebox] 高优先级开启` |
| 悬浮面板 | **开启** | `lib/models/config.dart` | `// [Gamebox] 悬浮面板开启` |
| 联动开关 | **关闭** | `lib/models/config.dart` | `// [Gamebox] 联动开关默认关闭` |
| 延迟动画 | **fast（50ms，UI 第一项）**（上游默认 standard/150ms） | `lib/models/generated/config.g.dart` | `// [Gamebox] 动画默认第一个（fast）` |
| 回环保护 | **跟随上游**（`@Default(true)`） | `lib/models/config.dart` | `// [Gamebox] 跟随上游` |

### 1.5 检查更新

| 项 | 值 | 文件 | 注释 |
|---|---|---|---|
| 检查更新端点 | `https://raw.githubusercontent.com/mouren1988/Bettbox/refs/heads/gamebox/version.json`（直接读 fork 的 `gamebox` 分支根目录的 `version.json`） | `lib/common/request.dart` `lib/common/constant.dart` | `// [Gamebox] 检查更新走 raw.githubusercontent.com 读 fork 的 gamebox 分支上的 version.json` |
| 仓库 | `mouren1988/Bettbox`（URL 模板里用 `$repository` 拼，sync 上游时务必确认这里指向 fork） | `lib/common/constant.dart` | `// [Gamebox] 仓库指向 fork（不上游原版）` |
| 数据源 | `gamebox` 分支根目录下的 `version.json`（**不**走 GitHub releases；用户不想发版） | `lib/common/constant.dart` | `const updateCheckUrl = 'https://raw.githubusercontent.com/$repository/refs/heads/gamebox/version.json';` |
| `version.json` 字段 | `{ "version": "1.19.5+2026100101", "notes": "" }`（`version` 包含 `+build` 后缀；`notes` 是 changelog 文本，可空字符串） | `https://github.com/mouren1988/Bettbox/blob/gamebox/version.json` | 用户自己维护；同步 `packageInfo.version+buildNumber` |
| 下载链接 | `https://v10.lanzoup.com/b013a2b1wh`（蓝奏云盘，**不**走 GitHub releases） | `lib/common/constant.dart` | `const downloadUrl = 'https://v10.lanzoup.com/b013a2b1wh';` |
| 客户端映射 | `version.json.version` → 显示给用户的「发现新版本」标题；`version.json.notes` → 弹窗正文；`downloadUrl` → 「前往下载」按钮的链接 | `lib/common/request.dart` `checkForUpdate()` | 内部用 `tag_name`/`body` 字段返回（兼容下游 controller / about 零改动） |
| 全局 User-Agent | `Gamebox`（无版本号；上游 Bettbox 是 `clash.meta`，本项目刻意不带版本号） | `lib/models/clash_config.dart` | `// [Gamebox] UA 默认 Gamebox（不带版本号）` |
| 自动检查周期 | **1 天**（上游默认 28 天；常量 `defaultUpdateDuration`） | `lib/controller.dart` `lib/common/constant.dart` | `// [Gamebox] 自动检查周期改为 1 天` |
| 触发时机 | 启动时 + 距上次 > 1 天 | `lib/controller.dart:1167` | `final forceCheck = (now - lastCheckTime) > defaultUpdateDuration.inMilliseconds;` |

### 1.6 应用标识

| 项 | 值 | 文件 | 注释 |
|---|---|---|---|
| AppIdentity.displayName | `Gamebox` | `lib/common/identity.dart` | `// [Gamebox] 个性标题 Bettbox → Gamebox` |
| 全局搜索替换 | `Bettbox` → `Gamebox`（除 git 仓库名/包名/外链） | 全局 | 同步脚本 `rg -l Bettbox lib/ | xargs sed -i 's/Bettbox/Gamebox/g'` |

### 1.7 首页 / 关于页

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 首页出站规则卡片 | **永久删除**（不让客户用全局；dashboard `DashboardWidget.outboundMode` 和 `outboundModeV2` 枚举值已从 `lib/enum/enum.dart` 删除，widget 文件保留为 stub；yaml 仍可启用全局模式） | `lib/enum/enum.dart` `lib/views/dashboard/widgets/outbound_mode.dart` | `// [Gamebox] 永久删除出站模式` |
| 连通性测试置顶平台 | `gemini, discord, youtube`（上游是 `spotify, discord, youtube`） | `lib/models/config.dart` | `// [Gamebox] 置顶平台 spotify→gemini` |
| 关于页 | **固定不随上游更新** | `lib/views/about.dart` | 见 §2 |
| 贡献者头像 | 只显示 `mouren1988` 本地头像 | `lib/views/about.dart` `assets/images/avatars/mouren1988.jpg` | `// [Gamebox] 贡献者只显示仓库维护者` |
| 关于页链接 | 使用说明 / 检查更新 / Telegram 群 / QQ 群 | `lib/views/about.dart` | `// [Gamebox] 关于页链接偏好` |

### 1.8 Panel 面板（用户认证）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 启动 Gate | `ValueListenableBuilder(panelUnlocked)` 未解锁显示 `PanelLoginGate`，解锁后显示 `HomePage` | `lib/application.dart` (`_AppHome` widget) | `// [Gamebox] 启动登录 Gate` |
| 修改密码入口 | 退出账号时显示 | `lib/views/dashboard/widgets/user_profile.dart` | `// [Gamebox] 退出账号菜单` |
| 头像 | 本地 `mouren1988.jpg`（不联网） | `lib/views/about.dart` | `// [Gamebox] 头像本地化` |

### 1.9 i18n 锁 zh_CN（设置页只显示简体中文）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| 设置页语言列表 | 只显示「简体中文」一项（`_LocaleItem._localeOptions` 改为 `const [Locale.fromSubtags(...)]`） | `lib/views/tools.dart` | `// [Gamebox] 语言入口只保留简体中文` |
| 显示映射 | `_nativeLocaleNames` 字典保留 `zh_CN` 老 key + 新增 `zh_Hans_CN` key，都映射到「简体中文」 | `lib/views/tools.dart` | `// [Gamebox] 字典保留原 key 不动` |
| 当前 locale 显示 | `currentLocale` 强行落到 `_localeOptions` 唯一项（`_LocaleItem.build`），保证 Radio 始终选中简体中文 | `lib/views/tools.dart` | `// [Gamebox] 即使 appSetting.locale 持久化的是老值...` |
| 持久化兼容 | `appSetting.locale` 如果之前是 en/ja/... 不会被强行擦（防止破坏老用户偏好存储） | `lib/models/config.dart` | 沿用上游存储格式 |
| `otherContributors` 文案 | 6 个 locale 的 arb 全部去掉「(随机排序)」/「(Random Order)」等尾巴；中文用「贡献者」 | `arb/intl_*.arb` | 关于页只显示维护者，不再有「随机排序」误导 |
| 关于页 `desc` | 缩短为「Gamebox 基于强大灵活的 Mihomo 内核深度打造，致力于更好的客户端体验。」（去掉「我们的愿景: Connecting Open Source and AI, Accelerating Innovation」英文尾巴） | `lib/l10n/intl/messages_zh_CN.dart` | intl_utils 自动重生成 |

**为什么这么做**：
- 上游 MaterialApp.locale 写死 zh-Hans-CN（见 §1.1），**选别的 locale 实际不生效**（下次冷启动被覆盖）
- 但设置页 Radio 列表还显示 7 项（zh_CN/zh_TC/en/ru/fa/ja/ko），**会误导用户以为能切换**
- 锁成只显示 zh_CN 消除误导
- 不强行擦 appSetting.locale，**保持存储格式兼容**（老用户升级不会因为 locale 字段缺失出 bug）

---

## 2. 关于页特殊处理

`lib/views/about.dart` 是**用户偏好版本**（不是上游 v1.19.5 默认），**rebase 时不要用 upstream/main 的 about.dart 覆盖**。

**重要**：rebase 之前先把本文件加一行 `// [Gamebox] do not rebase` 标记到 `lib/views/about.dart` 顶部，避免误操作。

---

## 3. 资源文件

### 3.1 头像

`assets/images/avatars/mouren1988.jpg` —— GitHub 仓库维护者头像，本地打包到安装包。

**二进制写入注意事项**：
- PowerShell `Set-Content` 会编码破坏 PNG/JPG 字节
- 必须用 `[System.IO.File]::WriteAllBytes()` 写入
- 写入后用 `git diff --stat` 确认是 `Bin ... -> ... bytes` 而不是文本 diff

### 3.2 图标 / 启动图

`assets/manual/app-icon.ico` 等二进制资源同理。

---

## 4. 注释规范

所有 Gamebox 定制代码必须带 `// [Gamebox]` 注释：

```dart
// [Gamebox] 说明
final value = somethingModified;

// [Gamebox] 第二行说明
// 上游默认值是 xxx，Gamebox 改为 yyy，理由是 zzz
```

**rebase 时如果遇到 `<<<<<<<` 冲突，Gamebox 那一段**总是**带 [Gamebox] 标记**——保留它。

---

## 5. 提交规范

Commit message 格式：

```
Gamebox: <一句话说明>

- <改动 1 文件>：<说明>
- <改动 2 文件>：<说明>
- ...

同步上游命令：git fetch upstream && git rebase upstream/main
```

---

## 6. 测试

```bash
# 编译
flutter build windows --release --dart-define=APP_ENV=stable

# 启动
.\build\windows\x64\runner\Release\Gamebox.exe

# 验证项
# 1. 冷启动看到登录小窗（PanelLoginGate）
# 2. 登录后看到首页（HomePage）
# 3. 侧边栏/悬浮面板没有"备份与恢复"入口
# 4. 设置 → 关于页是 Gamebox 而不是 Bettbox
# 5. 8 项定制默认值（深色/中文/UA 等）符合预期
```

## 7. Inno Setup 安装器（只保留中文）

| 项 | 说明 | 文件 | 注释 |
|---|---|---|---|
| `[Languages]` 段 | 只声明 `chineseSimplified`（去掉 `english` 的 `Name: "english"; MessagesFile: "compiler:Default.isl"`） | `windows/packaging/exe/inno_setup.iss` | `// [Gamebox] 只保留简体中文 CustomMessages` |
| `[CustomMessages]` 段 | 删掉 hardcoded `english.ShuttingDownRunningApp=...` / `english.RemoveUserDataPrompt=...` 两行 | `windows/packaging/exe/inno_setup.iss` | 原因：没声明 `Name: "english"` 时 ISCC 会报 "Unknown language name "english"" |
| Liquid 模板 | `[Languages]` 段用 `{% for %}` 直接渲染，**不用 `{% if %}` 包裹 + `{% else %}` 兜底**（Liquid 的 `for` 块不接受 `else`，而 `if` 包裹是给 fallback english 用的，删掉后整段包裹也不需要了） | `windows/packaging/exe/inno_setup.iss` | `// [Gamebox] ...` |
| `make_config.yaml` `locales` | 只列 zh 一项（删 en） | `windows/packaging/exe/make_config.yaml` | `// [Gamebox] 只保留简体中文：去掉 en，避免安装器弹出 language dialog` |
| 9 个 verification 警告 | `SourceVerificationFailed` / `StatusDownloadFiles` / `StopExtraction` / `VerificationFileHashIncorrect` / `VerificationFileNameIncorrect` / `VerificationFileSizeIncorrect` / `VerificationFileTagIncorrect` / `VerificationKeyNotFound` / `VerificationSignatureDoesntExist` / `VerificationSignatureInvalid` 在 `ChineseSimplified.isl` 未定义 → 走 Default.isl 英文 fallback | — | 不致命，verification 流程出现时是英文消息（业务消息全中文） |

**为什么这么做**：
- 上游 Bettbox 默认带 6 个 locale + english Default，安装时 ISCC 自动弹「Select Language」对话框
- 既然我们只发布中文版（§1.1 固定 locale + §1.9 设置页只显示中文），**language dialog 完全没有意义**（用户语言选什么都被覆盖回 zh-CN）
- 删 english 后 ISCC 直接进中文安装流程，**节省一个点击**

**rebase / sync 时**：
- 如果 upstream 重新加回 `english` 到 `[Languages]` 段，**立刻删掉**
- 如果 upstream 在 `[CustomMessages]` 加了 `english.*` 行，**同步删掉**
- 同步脚本检查点：`grep -n "english" windows/packaging/exe/inno_setup.iss` 必须只有 ISCC compiler 内置引用（`"compiler:Default.isl"` 那条作为兜底已经删除）


