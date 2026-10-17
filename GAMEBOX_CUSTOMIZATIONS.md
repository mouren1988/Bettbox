# Gamebox 定制化修改清单

> 本文件记录 Gamebox 相对 upstream Bettbox 的所有定制化修改。
> 任何修改都要带 `// [Gamebox]` 注释，并同步更新本文件。

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
| 全局 User-Agent | `Gamebox/1.19.6` | `lib/models/clash_config.dart` | `// [Gamebox] 全局 UA` |
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
| 检查更新端点 | `https://v4.gh-proxy.org/https://github.com/mouren1988/Bettbox/releases/latest`（gh-proxy 包裹的 GitHub releases 页面，仍走 302 → tag 解析） | `lib/common/request.dart` | `// [Gamebox] 检查更新走 gh-proxy 镜像` |
| 仓库 | `mouren1988/Bettbox` | `lib/common/constant.dart` | `// [Gamebox] 仓库指向 fork（不上游原版）` |
| 全局 User-Agent | `Gamebox`（无版本号；上游是 `clash.meta`，本项目刻意不带版本号） | `lib/models/clash_config.dart` | `// [Gamebox] UA 默认 Gamebox（不带版本号）` |
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
