import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/views/views.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Navigation {
  static Navigation? _instance;

  List<NavigationItem> getItems({
    bool openLogs = false,
    bool hasProxies = false,
  }) {
    return [
      NavigationItem(
        keep: false,
        icon: const Icon(Icons.home),
        label: PageLabel.dashboard,
        builder: (_) =>
            DashboardView(key: const GlobalObjectKey(PageLabel.dashboard)),
      ),
      NavigationItem(
        icon: const Icon(Icons.explore),
        label: PageLabel.proxies,
        builder: (_) => ProviderScope(
          overrides: [queryProvider.overrideWith(() => Query())],
          child: ProxiesView(key: const GlobalObjectKey(PageLabel.proxies)),
        ),
        modes: hasProxies
            ? [NavigationItemMode.mobile, NavigationItemMode.desktop]
            : [],
      ),
      // [Gamebox] 隐藏订阅入口（防止用户误操作配置文件）：
      // - 侧边栏、悬浮面板、设置搜索项都通过 Navigation.getItems() 派生,
      //   这里注释掉就一并消失。
      // - 业务路径（心跳静默同步、24h 定时器、登录导入）不依赖 UI 入口,
      //   仍可正常工作。
      // NavigationItem(
      //   icon: const Icon(Icons.folder_shared),
      //   label: PageLabel.profiles,
      //   builder: (_) =>
      //       ProfilesView(key: const GlobalObjectKey(PageLabel.profiles)),
      // ),
      NavigationItem(
        icon: Icon(Icons.view_timeline_rounded),
        label: PageLabel.requests,
        builder: (_) =>
            RequestsView(key: const GlobalObjectKey(PageLabel.requests)),
        description: 'requestsDesc',
        modes: [NavigationItemMode.desktop, NavigationItemMode.more],
      ),
      NavigationItem(
        icon: Icon(Icons.cable_rounded),
        label: PageLabel.connections,
        builder: (_) =>
            ConnectionsView(key: const GlobalObjectKey(PageLabel.connections)),
        description: 'connectionsDesc',
        modes: [NavigationItemMode.desktop, NavigationItemMode.more],
      ),
      NavigationItem(
        icon: Icon(Icons.storage),
        label: PageLabel.resources,
        description: 'resourcesDesc',
        builder: (_) =>
            ResourcesView(key: const GlobalObjectKey(PageLabel.resources)),
        modes: [NavigationItemMode.more],
      ),
      NavigationItem(
        icon: const Icon(Icons.terminal_outlined),
        label: PageLabel.script,
        description: 'scriptDesc',
        builder: (_) =>
            ScriptsView(key: const GlobalObjectKey(PageLabel.script)),
        modes: [NavigationItemMode.more],
      ),
      NavigationItem(
        icon: const Icon(Icons.adb_rounded),
        label: PageLabel.logs,
        builder: (_) => LogsView(key: const GlobalObjectKey(PageLabel.logs)),
        description: 'logsDesc',
        modes: [NavigationItemMode.desktop, NavigationItemMode.more],
      ),
      NavigationItem(
        icon: Icon(Icons.construction),
        label: PageLabel.tools,
        builder: (_) => ToolsView(key: const GlobalObjectKey(PageLabel.tools)),
        modes: [NavigationItemMode.desktop, NavigationItemMode.mobile],
      ),
    ];
  }

  Navigation._internal();

  factory Navigation() {
    _instance ??= Navigation._internal();
    return _instance!;
  }
}

final navigation = Navigation();
