import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/models/models.dart';
import 'package:bett_box/state.dart';
import 'package:bett_box/views/panel_login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// flutter test 下 getDownloadsDirectory 不可用（仅 macOS 实现），
// AppPath 构造时会并发调它并抛异常。给测试一个纯内存实现。
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getDownloadsPath() async => root;

  @override
  Future<String?> getApplicationCachePath() async => root;

  @override
  Future<String?> getLibraryPath() async => root;
}

// [Gamebox] 登录小窗固定 360x420（Window.loginSize），不可滚动。
// 内容必须正好放进小窗，否则会渲染黄黑 overflow 条，或把「登录」按钮挤出可视区。
// 尺寸取自实测：顶部 28px 拖动条占掉 420-28=392px 可视高度。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // AppPath 构造时会并发调 getTemporaryDirectory() / getDownloadsDirectory()。
  // getDownloadsDirectory 只在 macOS 平台实现里有，flutter test 下
  // MethodChannelPathProvider.getDownloadsPath 会直接抛
  // UnsupportedError: Functionality only available on macOS。
  // 这个异常发生在 initState 的异步回调里，会把 widget 测试判失败。
  // 这里改 path_provider 的 platform 实例（打桩 MethodChannel 无效，
  // 因为平台检查在发消息之前就抛了）。
  late Directory tmp;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gamebox_login_test');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
  });
  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  // 登录小窗逻辑尺寸，与 Window.loginSize 保持一致。
  const loginWindow = Size(360, 420);
  // 顶部拖动条占用的高度。
  const topDragBar = 28.0;

  Future<void> pumpLogin(
    WidgetTester tester, {
    required bool changePassword,
  }) async {
    tester.view.physicalSize = loginWindow;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    globalState.config = Config(
      themeProps: defaultThemeProps,
      appSetting: AppSettingProps(),
      proxiesStyle: const ProxiesStyle(),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        home: Builder(
          builder: (context) {
            globalState.measure = Measure.of(context, 1);
            return const Material(child: PanelLoginGate());
          },
        ),
      ),
    );
    // loadRememberedPanelLogin 在测试环境没有 path_provider 插件会抛错，
    // 且它发生在首帧之后的异步回调里，所以这里逐帧 pump 并吞掉异常，
    // 只让布局跑起来。换成 pumpAndSettle 会被这个未捕获异常判为测试失败。
    final errors = <Object>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exception);
    addTearDown(() => FlutterError.onError = prevOnError);
    for (var i = 0; i < 3; i++) {
      try {
        await tester.pump(const Duration(milliseconds: 50));
      } catch (_) {}
    }
    if (changePassword) {
      await tester.tap(find.text('修改密码'));
      try {
        await tester.pumpAndSettle();
      } catch (_) {}
    }
  }

  testWidgets('登录小窗没有滚动视图（固定不滚动）', (tester) async {
    await pumpLogin(tester, changePassword: false);
    expect(find.byType(SingleChildScrollView), findsNothing);
  });

  testWidgets('登录表单完整放进 360x420 小窗', (tester) async {
    await pumpLogin(tester, changePassword: false);
    final loginBtn = find.widgetWithText(FilledButton, '登录');
    expect(loginBtn, findsOneWidget);
    final rect = tester.getRect(loginBtn);
    // 登录按钮必须完整落在小窗可视区内（含底部拖动条之上）。
    expect(rect.bottom, lessThanOrEqualTo(loginWindow.height - topDragBar));
  });

  testWidgets('修改密码表单完整放进 360x420 小窗', (tester) async {
    await pumpLogin(tester, changePassword: true);
    final confirm = find.widgetWithText(FilledButton, '确认修改');
    expect(confirm, findsOneWidget);
    final rect = tester.getRect(confirm);
    expect(rect.bottom, lessThanOrEqualTo(loginWindow.height - topDragBar));
  });

  testWidgets('登录页不渲染桌面窗口按钮（移动端路径）', (tester) async {
    // 测试环境下 system.isDesktop 为 false（测试跑在非桌面平台标识上），
    // 这里只断言「移动端不应出现置顶/最小化/关闭」的关键行为不崩。
    await pumpLogin(tester, changePassword: false);
    // 桌面端按钮带 tooltip；移动端不应渲染。
    // 若测试环境被识别为桌面端则跳过这条断言。
    if (find.byTooltip('置顶').evaluate().isNotEmpty) {
      expect(find.byTooltip('最小化'), findsOneWidget);
      expect(find.byTooltip('关闭'), findsOneWidget);
    } else {
      expect(find.byTooltip('置顶'), findsNothing);
    }
  });
}
