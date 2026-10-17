import 'dart:async';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/config.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class Contributor {
  final String avatar;
  final String name;

  const Contributor({required this.avatar, required this.name});
}

// [Gamebox] About 页固定链接（与 iGame 保持一致：TG 群/QQ 群 + Gamebox 仓库）。
const _groupUrl = 'https://t.me/+UOt2DJZ7Qyo2YzA9';
const _qqGroupUrl = 'https://qm.qq.com/q/xjr21slB74';
const _repoAvatar = 'assets/images/avatars/mouren1988.jpg';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Future<void> _checkUpdate(BuildContext context) async {
    final commonScaffoldState = context.commonScaffoldState;
    if (commonScaffoldState?.mounted != true) return;
    final data = await globalState.appController.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
      needLoading: true,
    );
    globalState.appController.checkUpdateResultHandle(
      data: data,
      handleError: true,
    );
  }

  List<Widget> _buildMoreSection(BuildContext context) {
    // [Gamebox] 复古到上游 1.19.4 风格：2列网格 + 纯文字 + 右侧 16px 小图标，
    // 去掉彩色方块 / prefix / external 角标，让“更多”区回归简洁。
    // 只保留 4 项：使用说明 / 检查更新 / Telegram群组 / QQ交流群。
    // [Gamebox] 显式传 textColor: onSurface 把 OutlinedButton 内部文字色
    // 从 colorScheme.primary（深色主题下偏淡蓝/淡紫）改为 onSurface（白），
    // 避免 M3 AnimatedDefaultTextStyle 的 primary 套色。
    return generateSection(
      title: appLocalizations.more,
      textColor: context.colorScheme.onSurface,
      items: [
        _LinkGridRow(
          left: _LinkGridTile(
            title: '使用说明',
            icon: Icons.star,
            onTap: () => globalState.openUserManual(),
          ),
          right: _LinkGridTile(
            title: appLocalizations.checkUpdate,
            icon: Icons.refresh,
            onTap: () => _checkUpdate(context),
          ),
        ),
        _LinkGridRow(
          left: _LinkGridTile(
            title: 'Telegram群组',
            icon: Icons.open_in_new,
            onTap: () => globalState.openUrl(_groupUrl),
          ),
          right: _LinkGridTile(
            title: 'QQ交流群',
            icon: Icons.open_in_new,
            onTap: () => globalState.openUrl(_qqGroupUrl),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection() {
    // ===== [Gamebox] 关于页 → 其他贡献者 =====
    // 上游 1.19.4：随机滚动显示一批开源贡献者头像。
    // Gamebox：只显示仓库维护者 mouren1988 的头像（_repoAvatar）。
    // 头像文件位置：assets/images/avatars/mouren1988.jpg
    // 同步上游时如果把头像换成自己的，**必须用二进制方式提交**（不要用
    // PowerShell `Set-Content` / `Out-File`，会把文件当 UTF-8 文本重写，
    // 高位字节全部被替换为 U+FFFD，导致 CircleAvatar 加载失败回退到绿底）。
    return generateSection(
      separated: false,
      title: appLocalizations.otherContributors,
      items: [
        ListItem(
          title: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 24,
              children: const [
                Avatar(
                  contributor: Contributor(
                    avatar: _repoAvatar,
                    name: 'mouren1988',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // [Gamebox] 顶层那个 ListTile(title: Column(...)) 直接放在 generateListView
    // 的 items 数组里时，运行时 Flutter 抛 "ListTile widgets require a Material
    // widget ancestor" 异常（generateListView 的兜底 Padding + CommonCard
    // 里 OutlinedButton 提供的 Material 跨了 LookupBoundary，仍然不满足
    // ListTile 的 debugCheckHasMaterial 检查），结果整页只剩一个红屏错误
    // 块，所有正常内容都看不见。
    // 在 ListTile 外面套一层 Material(type: transparency) 显式提供一个
    // Material 祖先，是最稳的修法（不影响 ListTile 的视觉外观，transparency
    // 不会画任何背景）。同步上游时如果 ListTile 被改成别的 widget，确认
    // 父链里有 Material 即可。
    final items = [
      // [Gamebox] 顶层那个 ListTile 直接放在 generateListView 的 items 数组
      // 里时，运行时 Flutter 抛 "ListTile widgets require a Material widget
      // ancestor" 异常，整页空白（截图见用户报告）。
      // 原因：generateListView 的兜底分支用 Padding + CommonCard 包 ListTile，
      // CommonCard 内 OutlinedButton 提供的 Material 跨了 LookupBoundary，
      // 仍然不满足 ListTile 的 debugCheckHasMaterial 检查。
      // 最稳的修法：直接在 ListTile 外面套一层 Material(type: transparency)
      // 显式提供 Material 祖先（transparency 不画任何背景，不影响视觉）。
      // 同步上游时如果 ListTile 被换成别的 widget，确认父链里有 Material 即可。
      Material(
        type: MaterialType.transparency,
        child: ListItem(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Consumer(
              builder: (_, ref, _) {
                return _DeveloperModeDetector(
                  child: Wrap(
                    spacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            // [Gamebox] 显式 onSurface：ListItem 内部
                            // ListTile 在 OutlinedButton 内时，ListTile
                            // 透传的 titleTextStyle 没指定 color，会被
                            // Material AnimatedDefaultTextStyle 套成
                            // colorScheme.primary。
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            '${globalState.packageInfo.version}+${globalState.packageInfo.buildNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onEnterDeveloperMode: () {
                    ref
                        .read(appSettingProvider.notifier)
                        .updateState(
                          (state) => state.copyWith(developerMode: true),
                        );
                    context.showNotifier(
                      appLocalizations.developerModeEnableTip,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.desc,
              // [Gamebox] 同上，显式 onSurface 锁死文字色。
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        ),
      ),
      const SizedBox(height: 12),
      ..._buildContributorsSection(),
      ..._buildMoreSection(context),
    ];
    return generateListView(items);
  }
}

class Avatar extends StatelessWidget {
  final Contributor contributor;

  const Avatar({super.key, required this.contributor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircleAvatar(foregroundImage: AssetImage(contributor.avatar)),
        ),
        const SizedBox(height: 4),
        Text(contributor.name, style: context.textTheme.bodySmall),
      ],
    );
  }
}

class _DeveloperModeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onEnterDeveloperMode;

  const _DeveloperModeDetector({
    required this.child,
    required this.onEnterDeveloperMode,
  });

  @override
  State<_DeveloperModeDetector> createState() => _DeveloperModeDetectorState();
}

class _DeveloperModeDetectorState extends State<_DeveloperModeDetector> {
  int _counter = 0;
  Timer? _timer;

  void _handleTap() {
    _counter++;
    if (_counter >= 5) {
      widget.onEnterDeveloperMode();
      _resetCounter();
    } else {
      _timer?.cancel();
      _timer = Timer(Duration(seconds: 1), _resetCounter);
    }
  }

  void _resetCounter() {
    _counter = 0;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: _handleTap, child: widget.child);
  }
}

class _LinkGridRow extends StatelessWidget {
  final _LinkGridTile left;
  final _LinkGridTile right;

  const _LinkGridRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.colorScheme.outlineVariant.withValues(
      alpha: context.colorScheme.brightness == Brightness.light ? 0.6 : 0.45,
    );
    // [Gamebox] _LinkGridTile 内部用了 InkWell，需要 Material 祖先。
    // 这个 Row 在 generateListView 兜底的 CommonCard(OutlinedButton) 内，
    // 但 material_ui 的 Scaffold 创建的 LookupBoundary 把 ListView 与外层
    // Material 隔开，OutlinedButton 提供的 Material 跨了边界，InkWell 仍
    // 报 "No Material widget found"。显式包一层 transparency Material
    // 修复（不画任何背景，不影响视觉）。
    return Material(
      type: MaterialType.transparency,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
              color: dividerColor,
            ),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}

class _LinkGridTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback onTap;

  const _LinkGridTile({required this.title, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                // [Gamebox] 必须显式 copyWith(color: onSurface)。Text style
                // 不指定 color 时，OutlinedButton 内部的 AnimatedDefaultTextStyle
                // 会用 labelLarge.copyWith(color: primary) 兜底渲染，导致所有
                // title 文字呈 primary 淡色。显式锁定 onSurface 后，Text 自身
                // 的 effective color 才是 onSurface，merge 不会回退。
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                // [Gamebox] 跟 title 一样显式锁 onSurface，避免被
                // OutlinedButton 内部 AnimatedDefaultTextStyle 的
                // iconColor(primary) 套色覆盖。
                color: context.colorScheme.onSurface,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
