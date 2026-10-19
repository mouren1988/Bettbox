import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:material_ui/material_ui.dart';

const appName = AppIdentity.displayName;
const appHelperService = WindowsHelperIdentity.serviceName;
const coreName = 'clash.meta';
const tunDeviceName = AppIdentity.tunDeviceName;
const browserUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36';
const packageName = AppIdentity.packageId;
final unixSocketPath = '/tmp/BettboxSocket_${Random().nextInt(10000)}.sock';
const maxTextScale = 1.4;
const minTextScale = 0.8;
final baseInfoEdgeInsets = EdgeInsets.symmetric(
  vertical: 16.ap,
  horizontal: 16.ap,
);

final defaultTextScaleFactor =
    WidgetsBinding.instance.platformDispatcher.textScaleFactor;
const httpTimeoutDuration = Duration(milliseconds: 5000);
const moreDuration = Duration(milliseconds: 100);
const animateDuration = Duration(milliseconds: 100);
const midDuration = Duration(milliseconds: 200);
const commonDuration = Duration(milliseconds: 300);
// [Gamebox] Auto-check interval.
// Upstream default is const Duration(days: 7).
// Gamebox forces Duration(days: 1) so the user gets update prompts more
// frequently. Sync upstream: keep this 1-day override.
const defaultUpdateDuration = Duration(days: 1);
const mmdbFileName = 'geoip.metadb';
const asnFileName = 'ASN.mmdb';
const geoSiteFileName = 'GeoSite.dat';
const bundleMRSFileName = 'BundleMRS.7z';
final double kHeaderHeight = system.isDesktop ? 40 : 0;
const profilesDirectoryName = 'profiles';
const localhost = '127.0.0.1';
const clashConfigKey = 'clash_config';
const configKey = 'config';
const customSidebarIconKey = 'custom_sidebar_icon';
const customDashboardTitleKey = 'custom_dashboard_title';
const double dialogCommonWidth = 300;
// [Gamebox] Update-check repository.
// Gamebox does NOT publish GitHub releases (the user does not want to).
// Instead, a `version.json` is committed on the `gamebox` branch of this
// fork, and checkForUpdate() reads it directly via raw.githubusercontent.com.
// Upstream Bettbox default is appshubcc/Bettbox; Gamebox points to
// mouren1988/Bettbox (the user's fork). Do NOT blindly sync upstream.
const repository = 'mouren1988/Bettbox';
// [Gamebox] Full version-check URL.
// Path: <repo>/refs/heads/<branch>/version.json  ->  mouren1988/Bettbox/refs/heads/gamebox/version.json
// v1.20.0 起 URL 加 v4.gh-proxy.org 前缀（直连 raw.githubusercontent.com 在 CN 网络不稳）。
// 用户可在 UI 的「资源」页编辑 URL 时去掉前缀回到直连。
// Sync upstream: keep this URL intact even if upstream changes `repository`.
const updateCheckUrl =
    'https://v4.gh-proxy.org/https://raw.githubusercontent.com/$repository/refs/heads/gamebox/version.json';
// [Gamebox] Download URL shown in the "new version" dialog.
// User does not publish GitHub releases; new builds go to Lanzou cloud disk.
// Sync upstream: keep this URL intact even if upstream changes its release URL.
const downloadUrl = 'https://v10.lanzoup.com/b013a2b1wh';
const ipInfoToken = String.fromEnvironment('IPINFO_TOKEN', defaultValue: '');
const defaultExternalController = '127.0.0.1:9090';
const maxMobileWidth = 600;
const maxLaptopWidth = 840;
double getFloatingBottomBarReserveHeight(BuildContext context) {
  final viewBottom = max(
    MediaQuery.viewPaddingOf(context).bottom,
    MediaQuery.paddingOf(context).bottom,
  );
  if (globalState.isAndroidTV) {
    return 132.0 + (viewBottom > 12 ? viewBottom - 12 : 0);
  }
  return 84.0 + (viewBottom > 12 ? viewBottom - 12 : 0);
}

double getFloatingBottomBarFABReserveHeight(BuildContext context) {
  final viewBottom = max(
    MediaQuery.viewPaddingOf(context).bottom,
    MediaQuery.paddingOf(context).bottom,
  );
  return 84.0 - min(viewBottom, 12.0);
}

// [Gamebox] 默认测试链接改为 Cloudflare（cp.cloudflare.com）。
const defaultTestUrl = 'https://cp.cloudflare.com/generate_204';

// Preset test URLs
const presetTestUrls = [
  'https://cp.cloudflare.com/generate_204',
  'https://g.cn/generate_204',
  'https://www.gstatic.com/generate_204',
  'https://www.google.com/generate_204',
  'https://www.apple.com/library/test/success.html',
];

// Preset NTP servers
const defaultNtpServer = 'time.apple.com';
const presetNtpServers = [
  'ntp.aliyun.com',
  'time.apple.com',
  'ntp.tencent.com',
  'time.windows.com',
  'time.cloudflare.com',
];

class CommonFilters {
  static final ImageFilter blur = ImageFilter.blur(
    sigmaX: 2,
    sigmaY: 2,
    tileMode: TileMode.mirror,
  );
}

final commonFilter = CommonFilters.blur;

const navigationItemListEquality = ListEquality<NavigationItem>();
const trackerInfoListEquality = ListEquality<TrackerInfo>();
const stringListEquality = ListEquality<String>();
const intListEquality = ListEquality<int>();
const logListEquality = ListEquality<Log>();
const groupListEquality = ListEquality<Group>();
const externalProviderListEquality = ListEquality<ExternalProvider>();
const packageListEquality = ListEquality<Package>();
const hotKeyActionListEquality = ListEquality<HotKeyAction>();
const stringAndStringMapEquality = MapEquality<String, String>();
const stringAndStringMapEntryIterableEquality =
    IterableEquality<MapEntry<String, String>>();
const delayMapEquality = MapEquality<String, Map<String, int?>>();
const stringSetEquality = SetEquality<String>();
const keyboardModifierListEquality = SetEquality<KeyboardModifier>();

const viewModeColumnsMap = {
  ViewMode.mobile: [2, 1],
  ViewMode.laptop: [3, 2],
  ViewMode.desktop: [4, 3],
};

const proxiesListStoreKey = PageStorageKey<String>('proxies_list');
const toolsStoreKey = PageStorageKey<String>('tools');
const profilesStoreKey = PageStorageKey<String>('profiles');

const defaultPrimaryColor = 0xFF00897B;

const maxLength = 256;
const maxLogLength = 512;

final mainIsolate = 'BettboxMainIsolate';

final serviceIsolate = 'BettboxServiceIsolate';

const defaultPrimaryColors = [
  0xFF1E293B,
  0xFF1976D2,
  defaultPrimaryColor,
  0xFFE91E63,
  0xFF7B1FA2,
  0xFFD97706,
  0xFF4F46E5,
  0xFF008FB6,
  0xFF388E3C,
  0xFF827717,
  0xFF795548,
];

const legacyPrimaryColors = [
  0xFF1E293B,
  0xFF1976D2,
  defaultPrimaryColor,
  0xFFE91E63,
  0xFF7B1FA2,
  0xFFD97706,
  0xFF334155,
];

const scriptTemplate = '''
const main = (config) => {
  return config;
}''';
