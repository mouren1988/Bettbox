import 'dart:async';
import 'dart:ui';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/providers/config.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
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
    // [Gamebox] 关于页链接。上游是 Github Releases、Telegram Group、Channel、FlClash、Mihomo。
    return generateSection(
      title: appLocalizations.more,
      items: [
        _LinkGridRow(
          left: _LinkTile(
            title: '使用说明',
            // [Gamebox] 沿用上游 Github Releases 的星星图标，只改打开的是使用说明。
            icon: Icons.star,
            onTap: () => globalState.openUserManual(),
          ),
          right: _LinkTile(
            title: appLocalizations.checkUpdate,
            icon: Icons.refresh,
            onTap: () => _checkUpdate(context),
          ),
        ),
        _LinkGridRow(
          left: _LinkTile(
            // [Gamebox] 上游文案是 Telegram Group。
            title: 'Telegram群组',
            icon: Icons.launch,
            onTap: () => globalState.openUrl(_groupUrl),
          ),
          right: _LinkTile(
            title: 'QQ交流群',
            icon: Icons.launch,
            onTap: () => globalState.openUrl(_qqGroupUrl),
          ),
        ),
        _LinkGridRow(
          left: _LinkTile(
            title: 'Github Releases',
            icon: Icons.star,
            external: true,
            onTap: () => globalState.openUrl(
              'https://github.com/appshubcc/Bettbox',
            ),
          ),
          right: _LinkTile(
            title: 'Channel',
            icon: Icons.campaign_outlined,
            external: true,
            onTap: () => globalState.openUrl(
              'https://telegram.me/appshub_channel',
            ),
          ),
        ),
        _LinkGridRow(
          left: _LinkTile(
            prefix: 'Forked from',
            title: 'FlClash',
            icon: Icons.code,
            onTap: () => globalState.openUrl(
              'https://github.com/chen08209/FlClash',
            ),
          ),
          right: _LinkTile(
            prefix: 'Powered by',
            title: 'Mihomo',
            icon: Icons.memory,
            onTap: () => globalState.openUrl(
              'https://github.com/MetaCubeX/mihomo',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildContributorsSection() {
    // [Gamebox] 只保留仓库头像。上游是一批贡献者头像并随机排序。
    return generateSection(
      separated: false,
      title: appLocalizations.otherContributors,
      items: [
        ListItem(
          title: const Align(
            alignment: Alignment.centerLeft,
            child: Avatar(
              contributor: Contributor(
                avatar: _repoAvatar,
                name: 'mouren1988',
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
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
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${globalState.packageInfo.version}+${globalState.packageInfo.buildNumber}',
                            style: Theme.of(context).textTheme.labelLarge,
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
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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

class _ContributorsRow extends StatefulWidget {
  final List<Contributor> contributors;

  const _ContributorsRow({required this.contributors});

  @override
  State<_ContributorsRow> createState() => _ContributorsRowState();
}

class _ContributorsRowState extends State<_ContributorsRow> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Shader _createEdgeShader(Rect rect) {
    final position = _controller.hasClients ? _controller.position : null;
    final hasBefore = position != null && position.extentBefore > 0;
    final hasAfter = position == null || position.extentAfter > 0;
    return LinearGradient(
      colors: [
        hasBefore ? Colors.transparent : Colors.white,
        Colors.white,
        Colors.white,
        hasAfter ? Colors.transparent : Colors.white,
      ],
      stops: const [0, 0.1, 0.9, 1],
    ).createShader(rect);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          thickness: 4,
          radius: const Radius.circular(2),
          child: ShaderMask(
            shaderCallback: _createEdgeShader,
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 24,
                children: [
                  for (final contributor in widget.contributors)
                    Avatar(contributor: contributor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkGridRow extends StatelessWidget {
  final _LinkTile left;
  final _LinkTile right;

  const _LinkGridRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          VerticalDivider(
            width: 1,
            thickness: 1,
            indent: 10,
            endIndent: 10,
            color: colorScheme.outlineVariant.withValues(
              alpha: colorScheme.brightness == Brightness.light ? 0.6 : 0.45,
            ),
          ),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String? prefix;
  final String title;
  final IconData icon;
  final bool external;
  final VoidCallback onTap;

  const _LinkTile({
    this.prefix,
    required this.title,
    required this.icon,
    this.external = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final prefix = this.prefix;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.opacity12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: colorScheme.primary),
                ),
                const Spacer(),
                Icon(
                  external ? Icons.arrow_outward : Icons.arrow_forward,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.opacity50,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  if (prefix != null)
                    TextSpan(
                      text: '$prefix ',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.opacity80,
                      ),
                    ),
                  TextSpan(text: title),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
