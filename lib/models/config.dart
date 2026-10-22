// ignore_for_file: invalid_annotation_target

import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:material_ui/material_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'models.dart';

part 'generated/config.freezed.dart';
part 'generated/config.g.dart';

const defaultBypassDomain = [
  '*.jd.com',
  '*.zhihu.com',
  '*.zhimg.com',
  '*.360buyimg.com',
  'localhost',
  '127.*',
  '[::1]',
  '*.local',
  '10.*',
  '172.16.*',
  '172.17.*',
  '172.18.*',
  '172.19.*',
  '172.20.*',
  '172.21.*',
  '172.22.*',
  '172.23.*',
  '172.24.*',
  '172.25.*',
  '172.26.*',
  '172.27.*',
  '172.28.*',
  '172.29.*',
  '172.30.*',
  '172.31.*',
  '192.168.*',
];

const defaultAppSettingProps = AppSettingProps();
const defaultVpnProps = VpnProps();
const defaultNetworkProps = NetworkProps();
const defaultProxiesStyle = ProxiesStyle();
const defaultWindowProps = WindowProps();
const defaultAccessControl = AccessControl();
final defaultThemeProps = ThemeProps(primaryColor: defaultPrimaryColor);

const List<DashboardWidget> defaultDashboardWidgets = [
  // [Gamebox] 首页顺序按确认过的排版：网络速度打头，用户信息紧跟其右侧。
  DashboardWidget.networkSpeed,
  DashboardWidget.userProfile,
  DashboardWidget.trafficUsage,
  DashboardWidget.networkDetection,
  DashboardWidget.intranetIp,
  DashboardWidget.mediaUnlockSmall,
  DashboardWidget.memoryInfo,
  DashboardWidget.connectionsCount,
  DashboardWidget.startButton,
];

// [Gamebox] 3.18 之前的 Android 默认布局，仅用于 safeFromJson 里识别
// 「用户从未手动编辑过首页」，命中则迁移到 defaultAndroidDashboardWidgets。
// 不要把这个列表当成可用默认值 —— 新默认值见下面那个。
//
// [Gamebox] 这里 _唯一_保留的是「3.18 之前、从未手动编辑过首页」的老默认：
// [networkSpeed, trafficUsage, networkDetection, connectionsCount,
//  memoryInfo, startButton]
// 这个列表是 #1「旧原版默认」、#2「3.18 我自己放错过的版本」
// (#2 在 safeFromJson 里识别一次后会被覆盖；见下面注释)。
const List<DashboardWidget> legacyAndroidDefaultDashboardWidgets = [
  DashboardWidget.networkSpeed,
  DashboardWidget.trafficUsage,
  DashboardWidget.networkDetection,
  DashboardWidget.connectionsCount,
  DashboardWidget.memoryInfo,
  DashboardWidget.startButton,
];

// [Gamebox] 3.18 第一次发版时我放错过的版本（userProfile 占了首行）。
// 只用来在 safeFromJson 里识别「没手动编辑但装过 3.18 第一次版」的用户，
// 命中则一并迁移到 defaultAndroidDashboardWidgets。下次清理时和上面那个一起删。
const List<DashboardWidget> misplacedV3_18DashboardWidgets = [
  DashboardWidget.userProfile,
  DashboardWidget.networkSpeed,
  DashboardWidget.trafficUsage,
  DashboardWidget.networkDetection,
  DashboardWidget.connectionsCount,
  DashboardWidget.memoryInfo,
  DashboardWidget.startButton,
];

// [Gamebox] Outbound-mode cards removed from default dashboard (desktop+Android).
// The DashboardWidget enum values (outboundMode / outboundModeV2) are
// permanently removed upstream of this list; see lib/enum/enum.dart.
// safeFromJson still handles stale config files that reference the old
// enum names by falling back to the default widget list.
//
// [Gamebox] Android 默认布局（v3.20 最终版，按用户手编版确认）。
// mobile view 固定 8 列：8 列 = 整行，4 列 = 半宽（一行并排两张）。
//   第 1 行：网络速度(networkSpeed，整行独占，最宽)
//   第 2 行：流量统计(trafficUsage) + 订阅信息(userProfile)
//   第 3 行：连通性测试(mediaUnlockSmall) + 网络检测(networkDetection)
//   第 4 行：启动开关(startButton) + 活跃连接(connectionsCount)
//   第 5 行：内存信息(memoryInfo)
//
// ⚠ 注意：这不是普通网格，而是 masonry 瀑布流（见 widgets/grid.dart 的
// `_getOrigin`）。每张卡落在当前 dy 最小的列上，所以「行」只是视觉结果，
// 真实落位由卡片高度决定。第 3 行右边的 networkDetection 比左边的
// mediaUnlockSmall 矮，右列下方会留一个空位；必须让**矮的** startButton
// 紧跟在 networkDetection 后面去填那个空位，高一点的 connectionsCount
// 才会被挤到下一行左侧。把这两张卡的顺序反过来就会得到
// 「连通性测试 | 网络检测 / 活跃连接 | 启动开关」的错版。
//
// 之前出过几版错的：
//   - 旧默认漏掉 userProfile（最早的原版清单）
//   - 3.18 第一次版把 userProfile 放首位，结果 8 列宽的 networkSpeed
//     被挤到第 2 行，整张首页布局崩。
//   - 3.19 第一版第 3 行放反(memoryInfo | networkDetection)，且漏了
//     mediaUnlock(连通性测试)。已通过 safeFromJson 迁移到本版。
//   - 3.20 误以为左右对调即可，来回改了两次，实际是瀑布流落位问题。
const List<DashboardWidget> defaultAndroidDashboardWidgets = [
  DashboardWidget.networkSpeed,
  DashboardWidget.trafficUsage,
  DashboardWidget.userProfile,
  DashboardWidget.mediaUnlockSmall,
  DashboardWidget.networkDetection,
  DashboardWidget.startButton,
  DashboardWidget.connectionsCount,
  DashboardWidget.memoryInfo,
];

List<DashboardWidget> dashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  try {
    return dashboardWidgets
            ?.map((e) => $enumDecode(_$DashboardWidgetEnumMap, e))
            .toList() ??
        (system.isAndroid
            ? defaultAndroidDashboardWidgets
            : defaultDashboardWidgets);
  } catch (_) {
    return system.isAndroid
        ? defaultAndroidDashboardWidgets
        : defaultDashboardWidgets;
  }
}

List<DashboardWidget> mobileDashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  try {
    return dashboardWidgets
            ?.map((e) => $enumDecode(_$DashboardWidgetEnumMap, e))
            .toList() ??
        defaultAndroidDashboardWidgets;
  } catch (_) {
    return defaultAndroidDashboardWidgets;
  }
}

List<DashboardWidget> desktopDashboardWidgetsSafeFromJson(
  List<dynamic>? dashboardWidgets,
) {
  List<DashboardWidget> widgets;
  try {
    widgets =
        dashboardWidgets
            ?.map((e) => $enumDecode(_$DashboardWidgetEnumMap, e))
            .toList() ??
        defaultDashboardWidgets;
  } catch (_) {
    widgets = defaultDashboardWidgets;
  }
// [Gamebox] 旧配置里没有这张卡时，放在网络速度后面，和确认过的排版一致。
  if (!widgets.contains(DashboardWidget.userProfile)) {
    final next = List<DashboardWidget>.from(widgets);
    final index = next.indexOf(DashboardWidget.networkSpeed);
    next.insert(index >= 0 ? index + 1 : 0, DashboardWidget.userProfile);
    return next;
  }
  return widgets;
}

// [Gamebox] 首页连通性测试默认三项。上游默认是 reddit、gemini、cloudflare。
// 同步时默认项按需求改成 spotify、discord、youtube。
// [Gamebox] Upstream pinned defaults: spotify, discord, youtube.
// Gamebox swaps spotify -> gemini (gemini is more practical in CN use).
const List<MediaPlatform> defaultPinnedMediaPlatforms = [
  MediaPlatform.gemini,
  MediaPlatform.discord,
  MediaPlatform.youtube,
];

List<MediaPlatform> pinnedMediaPlatformsSafeFromJson(
  List<dynamic>? pinnedMediaPlatforms,
) {
  try {
    if (pinnedMediaPlatforms == null) return defaultPinnedMediaPlatforms;
    final list = <MediaPlatform>[];
    for (final e in pinnedMediaPlatforms) {
      final str = e.toString();
      if (str == 'chatgpt') {
        list.add(MediaPlatform.openai);
        continue;
      }
      if (str == 'qqnews') {
        list.add(MediaPlatform.tencent);
        continue;
      }
      if (str == 'alidnsprobe') {
        list.add(MediaPlatform.alibaba);
        continue;
      }
      if (str == 'bytedance') {
        list.add(MediaPlatform.douyin);
        continue;
      }
      final p = MediaPlatform.values.where((v) => v.name == str).firstOrNull;
      if (p != null) list.add(p);
    }
    return list.isEmpty ? defaultPinnedMediaPlatforms : list;
  } catch (_) {
    return defaultPinnedMediaPlatforms;
  }
}

// ↑ upstream v1.19.7 新增：侧边栏 flyout 入口列表。
// [Gamebox] 原样跟随上游的 8 项（含 toolbox）。备份与恢复（backupAndRecovery）
// 虽然 enum 里还在，但 Gamebox 已在侧边栏隐藏（见 §3.2），所以不放进默认列表。
const List<SidebarFlyoutEntry> defaultSidebarFlyoutEntries = [
  SidebarFlyoutEntry.resources,
  SidebarFlyoutEntry.script,
  SidebarFlyoutEntry.toolbox,
  SidebarFlyoutEntry.theme,
  SidebarFlyoutEntry.basicConfig,
  SidebarFlyoutEntry.otherSettings,
  SidebarFlyoutEntry.application,
  SidebarFlyoutEntry.about,
];

List<SidebarFlyoutEntry> sidebarFlyoutEntriesSafeFromJson(
  List<dynamic>? sidebarFlyoutEntries,
) {
  try {
    return sidebarFlyoutEntries
            ?.map((e) => $enumDecode(_$SidebarFlyoutEntryEnumMap, e))
            .toList() ??
        defaultSidebarFlyoutEntries;
  } catch (_) {
    return defaultSidebarFlyoutEntries;
  }
}

@freezed
abstract class AppSettingProps with _$AppSettingProps {
  const factory AppSettingProps({
    String? locale,
    @Default(defaultDashboardWidgets)
    @JsonKey(fromJson: dashboardWidgetsSafeFromJson)
    List<DashboardWidget> dashboardWidgets,
    @Default(defaultAndroidDashboardWidgets)
    @JsonKey(fromJson: mobileDashboardWidgetsSafeFromJson)
    List<DashboardWidget> mobileDashboardWidgets,
    @Default(defaultDashboardWidgets)
    @JsonKey(fromJson: desktopDashboardWidgetsSafeFromJson)
    List<DashboardWidget> desktopDashboardWidgets,
    @Default(defaultPinnedMediaPlatforms)
    @JsonKey(fromJson: pinnedMediaPlatformsSafeFromJson)
    List<MediaPlatform> pinnedMediaPlatforms,
    @Default(false) bool mediaUnlockMoreStreamingPlatforms,
    @Default(false) bool mediaUnlockExtraDetails,
    @Default(true) bool mediaUnlockRefreshOnNodeChange,
    @Default(true) bool mediaUnlockColorfulIcons,
    @Default(true) bool mediaUnlockRefreshByCategory,
    @Default(true) bool onlyStatisticsProxy,
    @Default(false) bool autoLaunch,
    @Default(false) bool silentLaunch,
    @Default(false) bool smartDelayLaunch,
    @Default(false) bool autoRun,
    @Default(true) bool openLogs,
    @Default(true) bool closeConnections,
    @Default(true) bool logAiSearch,
    @Default(true) bool flushDnsOnNetworkChange,
    @Default(defaultTestUrl) String testUrl,
    // [Gamebox] 联动开关（首页独立启动按钮）默认关闭。上游默认 true。
    @Default(false) bool showStartSwitch,
    @Default(StartSwitchStyle.outlined) StartSwitchStyle startSwitchStyle,
    String? startSwitchOnLabel,
    String? startSwitchOffLabel,
    @Default(true) bool enableNavBarHapticFeedback,
    @Default(true) bool autoCheckUpdate,
    @Default(false) bool showLabel,
    // [Gamebox] 默认视为已同意，配合 controller 里不再弹出免责声明�?
    // 上游默认 false。同步时若恢复弹窗，这里改回 false�?
    @Default(true) bool disclaimerAccepted,
    @Default(true) bool minimizeOnExit,
    @Default(false) bool hidden,
    @Default(true) bool keepDockIcon,
    @Default(false) bool developerMode,
    @Default(RecoveryStrategy.compatible) RecoveryStrategy recoveryStrategy,
// ↑ upstream v1.19.7 新增：备份密码（Gamebox 隐藏了备份入口，但字段保留以兼容 upstream 数据结构）
    @Default('') String backupPassword,
    // [Gamebox] 增强工具 > 高优先级默认开启。上游默认 false。同步时保留 true。
    @Default(true) bool enableHighPriority,
    // [Gamebox] 主界面左侧菜单栏默认隐藏。上游默认 false。同步时保留 true。
    @Default(true) bool sidebarCollapsed,
    @Default(true) bool sidebarFlyout,
    @Default(false) bool sidebarFlyoutOutsideTools,
    @Default(SidebarFlyoutDelay.standard) SidebarFlyoutDelay sidebarFlyoutDelay,
    @Default(defaultSidebarFlyoutEntries)
    @JsonKey(fromJson: sidebarFlyoutEntriesSafeFromJson)
    List<SidebarFlyoutEntry> sidebarFlyoutEntries,
    String? dashboardTitle,
    @Default(<String>[]) List<String> toolboxTiles,
    @Default(false) bool mrsCopyRawLink,
    @JsonKey(unknownEnumValue: MrsRawSource.bettRules)
    @Default(MrsRawSource.bettRules)
    MrsRawSource mrsRawSource,
    @Default(true) bool mrsResolveDns,
    @Default(IperfOptions()) IperfOptions iperfOptions,
    @Default(LocalPingOptions()) LocalPingOptions localPingOptions,
    @Default(<String, String>{}) Map<String, String> mobileDashboardSizes,
    @Default(<String, String>{}) Map<String, String> desktopDashboardSizes,
  }) = _AppSettingProps;

  factory AppSettingProps.fromJson(Map<String, Object?> json) =>
      _$AppSettingPropsFromJson(json);

  factory AppSettingProps.safeFromJson(Map<String, Object?>? json) {
    var props = json == null
        ? defaultAppSettingProps
        : AppSettingProps.fromJson(json);

    if (json == null) {
      // [Gamebox] 安卓端（仅全新安装路径）的默认开关调整。
      // 仅当 `appSetting` 整个对象在 config.json 里都不存在时（= 全新
      // 安装）才覆盖，避免污染已有用户配置。
      // 老用户如果以后想覆盖他的 `flushDnsOnNetworkChange`，需要把字段
      // 单独提出来做识别（类似 3.18 dashboard 迁移）。
      if (system.isAndroid) {
        props = props.copyWith(
          mobileDashboardWidgets: defaultAndroidDashboardWidgets,
          // 增强工具 > 常规 > 网络变化时清理 DNS 缓存。
          // 桌面端写 true 也是死值，因为 controller 里 flushDns 调用
          // 的入口有 `system.isAndroid` 门禁。
          flushDnsOnNetworkChange: true,
        );
      }
      return props.copyWith(minimizeOnExit: true, openLogs: true);
    }

    final oldWidgets = json['dashboardWidgets'];
    if (oldWidgets is List) {
      final parsedOld = dashboardWidgetsSafeFromJson(oldWidgets);
      if (json['mobileDashboardWidgets'] == null) {
        props = props.copyWith(mobileDashboardWidgets: parsedOld);
      }
      if (json['desktopDashboardWidgets'] == null) {
        props = props.copyWith(desktopDashboardWidgets: parsedOld);
      }
    }

    // [Gamebox] 安卓默认布局迁移（见 GAMEBOX_CUSTOMIZATIONS.md 3.18）。
    // 老版本出过两版错的，都识别为「用户从未手动编辑过首页」并迁移到
    // defaultAndroidDashboardWidgets：
    //   1) 漏 userProfile 的老默认（上线前那个版本）
    //   2) 3.18 第一次发版把 userProfile 放首位的错版
    // 只要用户动过顺序、或增删过任何卡片（增删常用卡片会让长度或内容
    // 偏离该列表），就原样保留，不覆盖用户配置。
    // [Gamebox] 3.20 v2 回退：不按「元素集合相同」强制刷新顺序。
    // 瀑布流的实际落位由卡片高度决定，用户装新包就会拿到新默认值，
    // 无需覆盖持久化里的顺序（会破坏用户手动排的版）。
    if (system.isAndroid) {
      final currentMobile = props.mobileDashboardWidgets;
      if (_isLegacyAndroidDefaultDashboard(currentMobile) ||
          _isMisplacedV3_18Dashboard(currentMobile)) {
        props = props.copyWith(
          mobileDashboardWidgets: defaultAndroidDashboardWidgets,
        );
      }
    }

    return props.copyWith(minimizeOnExit: true, openLogs: true);
  }
}

/// [Gamebox] 3.18 之前漏 userProfile 的 Android 老默认。
const _legacyAndroidDefaultDashboardSet = {
  DashboardWidget.networkSpeed,
  DashboardWidget.trafficUsage,
  DashboardWidget.networkDetection,
  DashboardWidget.connectionsCount,
  DashboardWidget.memoryInfo,
  DashboardWidget.startButton,
};

bool _isLegacyAndroidDefaultDashboard(List<DashboardWidget> widgets) {
  if (widgets.length != legacyAndroidDefaultDashboardWidgets.length) {
    return false;
  }
  // 用集合 + 长度双重判断：用户可能把这 6 项**乱序**排过，也算是动过。
  final set = widgets.toSet();
  return set.length == widgets.length &&
      _legacyAndroidDefaultDashboardSet.containsAll(set);
}

/// [Gamebox] 3.18 第一次发版放错的版本（userProfile 排首位）。
bool _isMisplacedV3_18Dashboard(List<DashboardWidget> widgets) {
  if (widgets.length != misplacedV3_18DashboardWidgets.length) {
    return false;
  }
  for (var i = 0; i < widgets.length; i++) {
    if (widgets[i] != misplacedV3_18DashboardWidgets[i]) {
      return false;
    }
  }
  return true;
}

@freezed
abstract class AccessControl with _$AccessControl {
  const factory AccessControl({
    @Default(false) bool enable,
    @Default(AccessControlMode.rejectSelected) AccessControlMode mode,
    @Default([]) List<String> acceptList,
    @Default([]) List<String> rejectList,
    @Default([]) List<String> manualList,
    @JsonKey(unknownEnumValue: AccessSortType.none)
    @Default(AccessSortType.none)
    AccessSortType sort,
    @Default(false) bool isFilterSystemApp,
    @Default(false) bool isFilterNonInternetApp,
  }) = _AccessControl;

  factory AccessControl.fromJson(Map<String, Object?> json) =>
      _$AccessControlFromJson(json);
}

extension AccessControlExt on AccessControl {
  List<String> get currentList => switch (mode) {
    AccessControlMode.acceptSelected => acceptList,
    AccessControlMode.rejectSelected => rejectList,
  };
}

@freezed
abstract class WindowProps with _$WindowProps {
  const factory WindowProps({
    @Default(910) double width,
    @Default(620) double height,
    double? top,
    double? left,
    @Default(false) bool isPinned,
    @Default(1.0) double scaleFactor,
  }) = _WindowProps;

  factory WindowProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const WindowProps() : _$WindowPropsFromJson(json);
}

@freezed
abstract class VpnProps with _$VpnProps {
  const factory VpnProps({
    @Default(true) bool enable,
    // [Gamebox] Android「内核配�?> 网络」里的系统代理默认关闭�?
    // 上游默认 true。同步时保留 false�?
    @Default(false) bool systemProxy,
    @Default(false) bool allowBypass,
    @Default(true) bool bypassPrivateRoute,
    @Default(false) bool dozeSuspend,
    @Default(false) bool smartAutoStop,
    @Default('') String smartAutoStopNetworks,
    @Default(false) bool storeFix,
    @Default(false) bool networkFix,
    @Default(true) bool loopbackProtection,
    @Default(false) bool disableQuic,
    @Default(true) bool highPriorityNotification,
    @Default(true) bool networkSpeedNotification,
    @Default(false) bool excludeChina,
    // [Gamebox] 增强工具 > 托盘增强默认开启。上游默�?false。同步时保留 true�?
    @Default(true) bool trayEnhancement,
    @Default(TrayClickBehavior.showPanel)
    TrayClickBehavior trayLeftClickBehavior,
    @Default(TrayClickBehavior.showMenu)
    TrayClickBehavior trayRightClickBehavior,
    @Default(false) bool enableTraySpeed,
    @Default(true) bool alwaysShowTitleBar,
    // [Gamebox] 快速响应默认开启。仅 Android：Wi-Fi、流量、网线类型切换后�?
    // 延迟�?150 毫秒，把当前连接全部断开，让应用在新网络上重新连接�?
    // 上游这里已经�?true。同步时保留 true�?
    @Default(true) bool quickResponse,
    @Default(defaultAccessControl) AccessControl accessControl,
  }) = _VpnProps;

  factory VpnProps.fromJson(Map<String, Object?> json) =>
      _$VpnPropsFromJson(json);

  factory VpnProps.safeFromJson(Map<String, Object?>? json) {
    if (json == null) return defaultVpnProps;
    return VpnProps.fromJson(json);
  }
}

List<String> bypassDomainSafeFromJson(List<dynamic>? bypassDomain) {
  try {
    return bypassDomain
            ?.map((e) => e.toString())
            .where((e) => e != '::1')
            .toList() ??
        defaultBypassDomain;
  } catch (_) {
    return defaultBypassDomain;
  }
}

@freezed
abstract class NetworkProps with _$NetworkProps {
  const factory NetworkProps({
    // [Gamebox] 桌面端「内核配置 → 网络」系统代理默认关闭。上游默认 true。同步时保留 false。
    @Default(false) bool systemProxy,
    @Default(defaultBypassDomain)
    @JsonKey(fromJson: bypassDomainSafeFromJson)
    List<String> bypassDomain,
    @Default(true) bool bypassPrivateRoute,
    @Default([]) List<String> bypassPrivateRouteAddress,
    @Default(true) bool autoSetSystemDns,
  }) = _NetworkProps;

  factory NetworkProps.fromJson(Map<String, Object?>? json) =>
      json == null ? const NetworkProps() : _$NetworkPropsFromJson(json);
}

extension NetworkPropsExt on NetworkProps {
  List<String> get realBypassPrivateRouteAddress {
    if (bypassPrivateRouteAddress.isNotEmpty) return bypassPrivateRouteAddress;
    return system.isDesktop
        ? defaultDesktopBypassPrivateRouteAddress
        : defaultBypassPrivateRouteAddress;
  }
}

@freezed
abstract class ProxiesStyle with _$ProxiesStyle {
  const factory ProxiesStyle({
    @Default(ProxiesType.tab) ProxiesType type,
    @Default(ProxiesSortType.none) ProxiesSortType sortType,
    @Default(ProxiesLayout.standard) ProxiesLayout layout,
    @Default(ProxiesIconStyle.none) ProxiesIconStyle iconStyle,
    @Default(ProxyCardType.shrink) ProxyCardType cardType,
    // [Gamebox] 延迟动画默认值。UI 上第一个选项显示为「默认」，对应
    // DelayAnimationType.none（即不显示任何自定义动画，保留原生进度条）。
    // 同步上游时若 none 的中文翻译变了，这里只跟枚举值，不跟文案。
    @Default(DelayAnimationType.none) DelayAnimationType delayAnimation,
    @Default(true) bool syncDelayAnimation,
    @Default({}) Map<String, String> iconMap,
    @Default(250) int concurrencyLimit,
    @Default(true) bool autoStickyHeader,
    @Default(false) bool showHiddenItems,
    @Default(false) bool hasCustomizedStyle,
  }) = _ProxiesStyle;

  factory ProxiesStyle.fromJson(Map<String, Object?>? json) =>
      json == null ? defaultProxiesStyle : _$ProxiesStyleFromJson(json);
}

@freezed
abstract class TextScale with _$TextScale {
  const factory TextScale({
    @Default(false) bool enable,
    @Default(1.0) double scale,
  }) = _TextScale;

  factory TextScale.fromJson(Map<String, Object?> json) =>
      _$TextScaleFromJson(json);
}

@freezed
abstract class ThemeProps with _$ThemeProps {
  const factory ThemeProps({
    int? primaryColor,
    @Default(defaultPrimaryColors) List<int> primaryColors,
    // [Gamebox] 主题模式默认深色。上游是 ThemeMode.system。同步时保留 dark�?
    @Default(ThemeMode.dark) ThemeMode themeMode,
    @Default(DynamicSchemeVariant.content) DynamicSchemeVariant schemeVariant,
    @Default(false) bool pureBlack,
    @Default(TextScale()) TextScale textScale,
    @Default(false) bool useDarkIcon,
    @Default(false) bool useHarmonyFont,
    @Default(false) bool invertTrayIcon,
  }) = _ThemeProps;

  factory ThemeProps.fromJson(Map<String, Object?> json) =>
      _$ThemePropsFromJson(json);

  factory ThemeProps.safeFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return defaultThemeProps;
    }
    try {
      return ThemeProps.fromJson(json);
    } catch (_) {
      return defaultThemeProps;
    }
  }
}

@freezed
abstract class ScriptProps with _$ScriptProps {
  const factory ScriptProps({
    String? currentId,
    @Default([]) List<Script> scripts,
  }) = _ScriptProps;

  factory ScriptProps.fromJson(Map<String, Object?> json) =>
      _$ScriptPropsFromJson(json);
}

extension ScriptPropsExt on ScriptProps {
  String? get realId {
    final index = scripts.indexWhere((script) => script.id == currentId);
    if (index != -1) {
      return currentId;
    }
    return null;
  }

  Script? get currentScript {
    final index = scripts.indexWhere((script) => script.id == currentId);
    if (index != -1) {
      return scripts[index];
    }
    return null;
  }

  Future<ScriptProps> externalize() async {
    if (scripts.every((script) => script.content.isEmpty)) return this;
    final next = <Script>[];
    for (final script in scripts) {
      if (script.content.isEmpty) {
        next.add(script);
        continue;
      }
      try {
        next.add(await script.writeContent(script.content));
      } catch (e) {
        commonPrint.error('Failed to store script ${script.label}: $e');
        next.add(script);
      }
    }
    return copyWith(scripts: next);
  }
}

@freezed
abstract class Config with _$Config {
  const factory Config({
    @JsonKey(fromJson: AppSettingProps.safeFromJson)
    @Default(defaultAppSettingProps)
    AppSettingProps appSetting,
    @Default([]) List<Profile> profiles,
    @Default([]) List<HotKeyAction> hotKeyActions,
    String? currentProfileId,
    @Default(false) bool overrideDns,
    @Default(false) bool overrideNtp,
    @Default(false) bool overrideSniffer,
    @Default(false) bool overrideTunnel,
    @Default(false) bool overrideExperimental,
    @Default(true) bool overrideTestUrl,
    DAV? dav,
    @Default(defaultNetworkProps) NetworkProps networkProps,
    @JsonKey(fromJson: VpnProps.safeFromJson)
    @Default(defaultVpnProps)
    VpnProps vpnProps,
    @JsonKey(fromJson: ThemeProps.safeFromJson) required ThemeProps themeProps,
    @Default(defaultProxiesStyle) ProxiesStyle proxiesStyle,
    @Default(defaultWindowProps) WindowProps windowProps,
    @JsonKey(fromJson: ClashConfig.safeFormJson)
    @Default(defaultClashConfig)
    ClashConfig patchClashConfig,
    @Default(ScriptProps()) ScriptProps scriptProps,
    @Default('') String nodeExcludeFilter,
    @Default(5000) int healthCheckTimeout,
  }) = _Config;

  factory Config.fromJson(Map<String, Object?> json) => _$ConfigFromJson(json);

  factory Config.compatibleFromJson(Map<String, Object?> json) {
    try {
      final accessControlMap = json['accessControl'];
      final isAccessControl = json['isAccessControl'];
      if (accessControlMap != null) {
        (accessControlMap as Map)['enable'] = isAccessControl;
        if (json['vpnProps'] != null) {
          (json['vpnProps'] as Map)['accessControl'] = accessControlMap;
        }
      }
    } catch (_) {}

    // Migrate legacy AccessControl sort values: 'name' -> 'none', 'time' -> 'updateTime'
    try {
      void migrateSort(dynamic accessControl) {
        if (accessControl is Map) {
          final sort = accessControl['sort'];
          if (sort == 'name') {
            accessControl['sort'] = 'none';
          } else if (sort == 'time') {
            accessControl['sort'] = 'updateTime';
          }
        }
      }

      migrateSort(json['accessControl']);
      if (json['vpnProps'] is Map) {
        migrateSort((json['vpnProps'] as Map)['accessControl']);
      }
    } catch (_) {}

    // Migrate legacy int profile IDs to string
    try {
      final currentProfileId = json['currentProfileId'];
      if (currentProfileId != null && currentProfileId is int) {
        json['currentProfileId'] = currentProfileId.toString();
      }
    } catch (_) {}

    try {
      final profiles = json['profiles'];
      if (profiles != null && profiles is List) {
        for (final profile in profiles) {
          if (profile is Map) {
            final id = profile['id'];
            if (id != null && id is int) {
              profile['id'] = id.toString();
            }
          }
        }
      }
    } catch (_) {}

    try {
      final themeProps = json['themeProps'];
      if (themeProps is Map &&
          themeProps['primaryColor'] != legacyPrimaryColors.last) {
        final colors = themeProps['primaryColors'];
        if (colors is List &&
            intListEquality.equals(colors.cast<int>(), legacyPrimaryColors)) {
          themeProps.remove('primaryColors');
        }
      }
    } catch (_) {}

    return Config.fromJson(json);
  }
}

extension ConfigExt on Config {
  Profile? get currentProfile {
    return profiles.getProfile(currentProfileId);
  }
}
