import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:bett_box/clash/clash.dart';
import 'package:bett_box/common/common.dart';
import 'package:bett_box/common/external_control.dart';
import 'package:bett_box/l10n/l10n.dart';
import 'package:bett_box/manager/hotkey_manager.dart';
import 'package:bett_box/manager/manager.dart';
import 'package:bett_box/plugins/app.dart';
import 'package:bett_box/providers/providers.dart';
import 'package:bett_box/state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controller.dart';
import 'pages/pages.dart';
import 'panel/panel_auth.dart';
import 'views/panel_login.dart';

class Application extends ConsumerStatefulWidget {
  const Application({super.key});

  @override
  ConsumerState<Application> createState() => ApplicationState();
}

class ApplicationState extends ConsumerState<Application>
    with WidgetsBindingObserver {
  Timer? _autoUpdateGroupTaskTimer;
  Timer? _autoUpdateProfilesTaskTimer;
  // [Gamebox] 面板会话心跳（对齐 iGame：约 60s 一次 GET /v1/me）。
  Timer? _panelHeartbeatTimer;
  Timer? _panelHeartbeatFirstTimer;

  final _pageTransitionsTheme = const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  ColorScheme _getAppColorScheme({
    required Brightness brightness,
    int? primaryColor,
  }) {
    return ref.read(genColorSchemeProvider(brightness));
  }

  SwitchThemeData _switchTheme(ColorScheme colorScheme) {
    final isLight = colorScheme.brightness == Brightness.light;
    return SwitchThemeData(
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return isLight ? Colors.white : colorScheme.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return null;
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return isLight
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.lighten(6);
      }),
    );
  }

  InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    final isLight = colorScheme.brightness == Brightness.light;
    final border = _FieldInputBorder(
      borderSide: BorderSide(
        color: isLight
            ? colorScheme.outlineVariant
            : colorScheme.outline.withValues(alpha: 0.45),
      ),
    );
    final focusedBorder = _FieldInputBorder(
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    );
    final errorBorder = _FieldInputBorder(
      borderSide: BorderSide(color: colorScheme.error),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.brightness == Brightness.light
          ? Color.lerp(
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
              0.5,
            )
          : colorScheme.surfaceContainerHighest,
      border: border,
      enabledBorder: border,
      focusedBorder: focusedBorder,
      disabledBorder: _FieldInputBorder(
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (system.isAndroid) {
      unawaited(SystemNavigator.setFrameworkHandlesBack(true));
    }
    globalState.backgroundMode.addListener(_syncAutoUpdateTasks);
    globalState.panelUnlocked.addListener(_syncAutoUpdateTasks);
    globalState.panelUnlocked.addListener(_syncPanelHeartbeat);
    _syncAutoUpdateTasks();
    globalState.appController = AppController(context, ref);
    globalState.clearPanelSubscriptions = clearPanelDataOnExit;
    globalState.openMainAfterLogin = _openMainAfterLogin;
    // [Gamebox] 原生窗口在引擎就绪时已经按登录尺寸显示。第一帧后再聚焦一次。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (globalState.panelUnlocked.value) return;
      unawaited(window?.show());
      // [Gamebox] 登录页期间预热内核连接，与后面 init 共用，缩短托盘退出冷启动等待。
      unawaited(
        globalState.appController.preheatCoreWhileLogin().catchError((
          Object e,
        ) {
          commonPrint.log('preheat core during login: $e');
        }),
      );
    });
  }

  bool _mainStarted = false;

  Future<void> _openMainAfterLogin() async {
    // [Gamebox] 登录窗期间托盘是关掉的。进主界面后再允许创建。
    tray.releaseAfterLogin();
    final silent = globalState.config.appSetting.silentLaunch;
    final firstStart = !_mainStarted;

    if (firstStart) {
      // [Gamebox] 托盘退出 = 冷启动，必须先跑完与上游相同的 init（含自动连接），再亮主界面。
      // 以前先亮仪表盘再 init，TUN/内核阶段会在「网络检测/启动」上空转十几秒；
      // 退出账号再登录不重走 init，所以不卡。这里只调整时机，不改启动逻辑本身。
      try {
        await _initApp();
      } catch (e) {
        commonPrint.log('init after login: $e');
      }
    }

    final desktop = system.isDesktop && window != null;
    if (desktop) {
      // [Gamebox] 跟 RustDesk、Electron 一样：窗口先藏起来，主界面画完再显示。
      // 不在可见窗口上改尺寸。DWM 遮罩解开时会把旧的登录页补一帧。
      await window!.hideForTransition();
    }
    globalState.panelUnlocked.value = true;
    if (desktop) {
      await window!.showAsMainWindow();
      if (silent) {
        await window!.hide();
      } else {
        // [Gamebox] 预热帧不会真正画出来，窗口一显示就是白底。
        // 先在屏幕外显示并画出主界面，再挪回原位。
        final origin = await window!.parkOffscreen();
        await window!.showForTransition();
        await _waitPresentedFrames(2);
        await window!.moveTo(origin);
      }
    }

    if (!firstStart) {
      // [Gamebox] 退出账号后再登录：内核已在，只补托盘和自动连接。
      unawaited(
        globalState.appController.updateTray(true, false, true).catchError((
          Object e,
        ) {
          commonPrint.log('tray after login: $e');
        }),
      );
      if (globalState.config.appSetting.autoRun && !globalState.isStart) {
        unawaited(
          globalState.appController.updateStatus(true).catchError((Object e) {
            commonPrint.log('auto connect after login: $e');
          }),
        );
      }
    }
  }

  // [Gamebox] 窗口已在屏幕外显示，等真实帧画完。单帧超过 50ms 就继续，避免卡住。
  Future<void> _waitPresentedFrames(int count) async {
    for (var i = 0; i < count; i++) {
      final done = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!done.isCompleted) done.complete();
      });
      WidgetsBinding.instance.scheduleFrame();
      await Future.any([
        done.future,
        Future<void>.delayed(const Duration(milliseconds: 50)),
      ]);
    }
  }

  bool get _isForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
  }

  Future<void> _initApp() async {
    _mainStarted = true;
    globalState.mainStarted = true;
    final currentContext = globalState.navigatorKey.currentContext;
    if (currentContext != null && currentContext != context) {
      globalState.appController = AppController(currentContext, ref);
    }
    await globalState.appController.init();
    if (!appPath.isPortable) {
      try {
        await ExternalControl.start();
      } catch (e) {
        commonPrint.warn('ExternalControl start failed: $e');
      }
    }
    globalState.appController.initLink();
    if (system.isAndroid) {
      app.initShortcuts();
    }
    Future.delayed(const Duration(seconds: 3), () {
      globalState.warmupCommonDialog();
    });
  }

  @override
  Future<bool> didPopRoute() async {
    if (!system.isAndroid) return false;
    final navigator = globalState.navigatorKey.currentState;
    if (navigator == null) return false;
    try {
      if (!await navigator.maybePop()) {
        await globalState.appController.handleBackOrExit();
      }
    } catch (e) {
      commonPrint.warn('Back dispatch failed: $e');
    }
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncAutoUpdateTasks();
  }

  void _syncPanelHeartbeat() {
    // [Gamebox] 已登录就心跳，最小化也继续，好收到面板踢出。
    _panelHeartbeatFirstTimer?.cancel();
    _panelHeartbeatFirstTimer = null;
    _panelHeartbeatTimer?.cancel();
    _panelHeartbeatTimer = null;
    if (!globalState.panelUnlocked.value) return;
    _panelHeartbeatFirstTimer = Timer(const Duration(milliseconds: 2500), () {
      unawaited(tickPanelSessionHeartbeat());
    });
    _panelHeartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(tickPanelSessionHeartbeat());
    });
  }

  void _syncAutoUpdateTasks() {
    if (!globalState.panelUnlocked.value) {
      _autoUpdateGroupTaskTimer?.cancel();
      _autoUpdateGroupTaskTimer = null;
      _autoUpdateProfilesTaskTimer?.cancel();
      _autoUpdateProfilesTaskTimer = null;
      return;
    }
    final shouldRun = _isForeground && !globalState.backgroundMode.value;
    if (!shouldRun) {
      _autoUpdateGroupTaskTimer?.cancel();
      _autoUpdateGroupTaskTimer = null;
      if (!system.isDesktop) {
        _autoUpdateProfilesTaskTimer?.cancel();
        _autoUpdateProfilesTaskTimer = null;
      }
      return;
    }
    if (_autoUpdateGroupTaskTimer == null) {
      _autoUpdateGroupTask();
    }
    if (_autoUpdateProfilesTaskTimer == null) {
      _autoUpdateProfilesTask();
    }
  }

  void _autoUpdateGroupTask() {
    _autoUpdateGroupTaskTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => globalState.appController.updateGroupsDebounce(),
    );
  }

  void _autoUpdateProfilesTask() {
    _autoUpdateProfilesTaskTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => unawaited(globalState.appController.autoUpdateProfiles()),
    );
  }

  Widget _buildPlatformState(Widget child) {
    if (system.isDesktop) {
      return WindowManager(
        child: TrayManager(
          child: HotKeyManager(
            child: ProxyManager(child: SmartAutoStopManager(child: child)),
          ),
        ),
      );
    }
    return AndroidManager(
      child: TileManager(child: SmartAutoStopManager(child: child)),
    );
  }

  Widget _buildState(Widget child) {
    return AppStateManager(
      child: ClashManager(
        child: ConnectivityManager(
          onConnectivityChanged: (results) async {
            if (!results.contains(ConnectivityResult.vpn)) {
              unawaited(
                clashCore.closeConnections().then<void>(
                  (_) {},
                  onError: (Object e) =>
                      commonPrint.debug('closeConnections ignored: $e'),
                ),
              );
            }
            if (system.isMacOS || system.isLinux) {
              // Wait for DHCP and the default route to settle before moving the
              // managed DNS from the previous network to the new one.
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;
              final dnsState = ref.read(autoSetSystemDnsStateProvider);
              await system.updateDns(!(dnsState.a && dnsState.b));
            }
            globalState.appController.updateLocalNetwork();
            globalState.appController.addCheckIpNumDebounce();
          },
          child: child,
        ),
      ),
    );
  }

  Widget _buildPlatformApp(Widget child) {
    if (system.isDesktop) {
      return WindowHeaderContainer(child: child);
    }
    return VpnManager(child: child);
  }

  Widget _buildApp(Widget child) {
    return MessageManager(child: ThemeManager(child: child));
  }

  @override
  Widget build(context) {
    return _buildPlatformState(
      _buildState(
        Consumer(
          builder: (_, ref, child) {
            // [Gamebox] 语言固定简体中文，下方已写死 MaterialApp.locale，
            // 这里不再 watch appSettingProvider.locale。
            final themeProps = ref.watch(themeSettingProvider);
            final fontFamily = themeProps.useHarmonyFont
                ? 'HarmonyOS_Sans'
                : null;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: globalState.navigatorKey,
              navigatorObservers: [routeIdleObserver],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              builder: (themeContext, child) {
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: globalState.panelUnlocked,
                    builder: (_, unlocked, _) {
                      if (!unlocked) {
                        // [Gamebox] 必须用 MaterialApp builder 的 context 取主题。
                        // Application 的 context 在 MaterialApp 外面，只有默认浅色。
                        // 登录窗不再套标题栏占位，避免卡片外面多出一层底色。
                        return ColoredBox(
                          color: Theme.of(themeContext)
                              .colorScheme
                              .surfaceContainerHigh,
                          child: _buildApp(child!),
                        );
                      }
                      return ValueListenableBuilder<bool>(
                        valueListenable: globalState.animationEnabled,
                        builder: (_, enabled, _) {
                          return TickerMode(
                            enabled: enabled,
                            child: AppEnvManager(
                              child: _buildApp(
                                AppSidebarContainer(
                                  child: _buildPlatformApp(child!),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              scrollBehavior: BaseScrollBehavior(),
              title: appName,
              // ===== [Gamebox] 语言固定简体中文 =====
              // 行为：无论系统 locale 是什么、无论 appSetting.locale 是什么，
              // 冷启动 MaterialApp.locale 始终是 zh-Hans-CN，界面永远是简体中文。
              // 用户在「设置 → 语言」里切换只是改了 appSetting.locale（用于本会话临时调试），
              // 不会持久覆盖下次启动的 zh-Hans-CN。
              //
              // scriptCode: 'Hans' 是关键：material_ui 1.6.0 的 GlobalMaterialLocalizations
              // 用 locale.scriptCode 找翻译；只写 languageCode: 'zh' / countryCode: 'CN'
              // 时 scriptCode 是 null，TextField 报 "No MaterialLocalizations found"。
              // 同步上游时如果 material_ui 升到 1.7+ 修了 scriptCode 推断逻辑，
              // 这里仍然保留 Hans（向后兼容）。
              locale: const Locale.fromSubtags(
                languageCode: 'zh',
                scriptCode: 'Hans',
                countryCode: 'CN',
              ),
              supportedLocales: const [
                Locale.fromSubtags(
                  languageCode: 'zh',
                  scriptCode: 'Hans',
                  countryCode: 'CN',
                ),
              ],
              themeMode: themeProps.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                pageTransitionsTheme: _pageTransitionsTheme,
                scaffoldBackgroundColor: _getAppColorScheme(
                  brightness: Brightness.light,
                  primaryColor: themeProps.primaryColor,
                ).surfaceContainer,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                    systemStatusBarContrastEnforced: false,
                  ),
                ),
                colorScheme: _getAppColorScheme(
                  brightness: Brightness.light,
                  primaryColor: themeProps.primaryColor,
                ),
                fontFamily: fontFamily,
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  elevation: 3,
                  hoverElevation: 5,
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: _getAppColorScheme(
                    brightness: Brightness.light,
                    primaryColor: themeProps.primaryColor,
                  ).surfaceContainerLowest,
                  surfaceTintColor: Colors.transparent,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _getAppColorScheme(
                        brightness: Brightness.light,
                        primaryColor: themeProps.primaryColor,
                      ).outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                bottomSheetTheme: const BottomSheetThemeData(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
                popupMenuTheme: const PopupMenuThemeData(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                dividerTheme: DividerThemeData(
                  color: _getAppColorScheme(
                    brightness: Brightness.light,
                    primaryColor: themeProps.primaryColor,
                  ).outlineVariant.withValues(alpha: 0.45),
                  thickness: 1,
                  space: 1,
                ),
                inputDecorationTheme: _inputDecorationTheme(
                  _getAppColorScheme(
                    brightness: Brightness.light,
                    primaryColor: themeProps.primaryColor,
                  ),
                ),
                switchTheme: _switchTheme(
                  _getAppColorScheme(
                    brightness: Brightness.light,
                    primaryColor: themeProps.primaryColor,
                  ),
                ),
                chipTheme: ChipThemeData(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  side: BorderSide(
                    color: _getAppColorScheme(
                      brightness: Brightness.light,
                      primaryColor: themeProps.primaryColor,
                    ).outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                tooltipTheme: TooltipThemeData(
                  decoration: BoxDecoration(
                    color: _getAppColorScheme(
                      brightness: Brightness.light,
                      primaryColor: themeProps.primaryColor,
                    ).inverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  textStyle: TextStyle(
                    color: _getAppColorScheme(
                      brightness: Brightness.light,
                      primaryColor: themeProps.primaryColor,
                    ).onInverseSurface,
                    fontSize: 13,
                  ),
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                pageTransitionsTheme: _pageTransitionsTheme,
                scaffoldBackgroundColor: _getAppColorScheme(
                  brightness: Brightness.dark,
                  primaryColor: themeProps.primaryColor,
                ).toPureBlack(themeProps.pureBlack).surfaceContainer,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                    systemStatusBarContrastEnforced: false,
                  ),
                ),
                colorScheme: _getAppColorScheme(
                  brightness: Brightness.dark,
                  primaryColor: themeProps.primaryColor,
                ).toPureBlack(themeProps.pureBlack),
                fontFamily: fontFamily,
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  elevation: 3,
                  hoverElevation: 5,
                ),
                dialogTheme: DialogThemeData(
                  backgroundColor: _getAppColorScheme(
                    brightness: Brightness.dark,
                    primaryColor: themeProps.primaryColor,
                  ).toPureBlack(themeProps.pureBlack).surfaceContainerHigh,
                  surfaceTintColor: Colors.transparent,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.6),
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          _getAppColorScheme(
                                brightness: Brightness.dark,
                                primaryColor: themeProps.primaryColor,
                              )
                              .toPureBlack(themeProps.pureBlack)
                              .outlineVariant
                              .withValues(alpha: 0.5),
                    ),
                  ),
                ),
                bottomSheetTheme: const BottomSheetThemeData(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                ),
                popupMenuTheme: const PopupMenuThemeData(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                dividerTheme: DividerThemeData(
                  color:
                      _getAppColorScheme(
                            brightness: Brightness.dark,
                            primaryColor: themeProps.primaryColor,
                          )
                          .toPureBlack(themeProps.pureBlack)
                          .outlineVariant
                          .withValues(alpha: 0.25),
                  thickness: 1,
                  space: 1,
                ),
                inputDecorationTheme: _inputDecorationTheme(
                  _getAppColorScheme(
                    brightness: Brightness.dark,
                    primaryColor: themeProps.primaryColor,
                  ).toPureBlack(themeProps.pureBlack),
                ),
                switchTheme: _switchTheme(
                  _getAppColorScheme(
                    brightness: Brightness.dark,
                    primaryColor: themeProps.primaryColor,
                  ).toPureBlack(themeProps.pureBlack),
                ),
                chipTheme: ChipThemeData(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  side: BorderSide(
                    color:
                        _getAppColorScheme(
                              brightness: Brightness.dark,
                              primaryColor: themeProps.primaryColor,
                            )
                            .toPureBlack(themeProps.pureBlack)
                            .outlineVariant
                            .withValues(alpha: 0.5),
                  ),
                ),
                tooltipTheme: TooltipThemeData(
                  decoration: BoxDecoration(
                    color: _getAppColorScheme(
                      brightness: Brightness.dark,
                      primaryColor: themeProps.primaryColor,
                    ).toPureBlack(themeProps.pureBlack).inverseSurface,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  textStyle: TextStyle(
                    color: _getAppColorScheme(
                      brightness: Brightness.dark,
                      primaryColor: themeProps.primaryColor,
                    ).toPureBlack(themeProps.pureBlack).onInverseSurface,
                    fontSize: 13,
                  ),
                ),
              ),
              home: child!,
            );
          },
          child: const _AppHome(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    globalState.backgroundMode.removeListener(_syncAutoUpdateTasks);
    globalState.panelUnlocked.removeListener(_syncAutoUpdateTasks);
    globalState.panelUnlocked.removeListener(_syncPanelHeartbeat);
    WidgetsBinding.instance.removeObserver(this);
    linkManager.destroy();
    _panelHeartbeatFirstTimer?.cancel();
    _panelHeartbeatTimer?.cancel();
    _autoUpdateGroupTaskTimer?.cancel();
    _autoUpdateProfilesTaskTimer?.cancel();
    ExternalControl.stop();
    if (!system.isAndroid && !globalState.isExiting) {
      unawaited(globalState.appController.handleExit());
    }
    super.dispose();
  }
}

// [Gamebox] 冷启动的路由就是登录页。登录成功后同一条路由换成主页，不另开窗口。
class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: globalState.panelUnlocked,
      builder: (_, unlocked, _) {
        if (!unlocked) return const PanelLoginGate();
        return const HomePage();
      },
    );
  }
}

class _FieldInputBorder extends InputBorder {
  const _FieldInputBorder({super.borderSide = BorderSide.none});

  static const _borderRadius = BorderRadius.all(Radius.circular(16));

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  _FieldInputBorder copyWith({BorderSide? borderSide}) {
    return _FieldInputBorder(borderSide: borderSide ?? this.borderSide);
  }

  @override
  ShapeBorder scale(double t) {
    return _FieldInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is _FieldInputBorder) {
      return _FieldInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is _FieldInputBorder) {
      return _FieldInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(_borderRadius.toRRect(rect).deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_borderRadius.toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) {
      return;
    }
    canvas.drawRRect(
      _borderRadius.toRRect(rect).deflate(borderSide.width / 2),
      borderSide.toPaint(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _FieldInputBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
