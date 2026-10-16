import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:math' as math;

import 'package:bett_box/common/common.dart';
import 'package:bett_box/state.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_ext/window_ext.dart';
import 'package:window_manager/window_manager.dart';

class Window {
  // [Gamebox] 登录小窗固定宽 360、高 420，用来看实际窗口效果。
  static const loginSize = Size(360, 420);

  Future<void> init() async {
    final props = globalState.config.windowProps;
    if (system.isWindows) {
      protocol.register('clash');
      protocol.register('clashmeta');
      protocol.register('flclash');
      protocol.register('gamebox');
      protocol.register('bettbox');
    }
    await windowManager.ensureInitialized();
    if (system.isMacOS && !globalState.config.appSetting.keepDockIcon) {
      try {
        await windowExtManager.setDockIconVisible(false);
      } catch (e) {
        commonPrint.warn('Apply dock icon visibility failed: $e');
      }
    }
    // [Gamebox] 冷启动只排登录小窗。登录成功后再恢复保存的主窗口尺寸。
    WindowOptions windowOptions = const WindowOptions(
      size: loginSize,
      minimumSize: loginSize,
      maximumSize: loginSize,
    );
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAlwaysOnTop(props.isPinned);
    await windowManager.setResizable(false);
    if (!system.isMacOS) {
      await windowManager.setAlignment(Alignment.center);
    }
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true);
      // [Gamebox] 引擎就绪后只显示登录小窗。这里不能走 Window.show，控制器还没建好。
      await windowManager.show();
      await windowManager.focus();
      // [Gamebox] 登录小窗四角稍微收圆。进入主界面前会取消。
      _applyLoginWindowShape(rounded: true);
    });
  }

  Future<void> _placeSavedWindow() async {
    final props = globalState.config.windowProps;
    if (system.isMacOS) return;
    final left = props.left;
    final top = props.top;
    if (left == null || top == null) {
      await windowManager.setAlignment(Alignment.center);
      return;
    }
    final savedDpr = props.scaleFactor;
    final currentDpr = windowManager.getDevicePixelRatio();

    final physLeft = left * savedDpr;
    final physTop = top * savedDpr;
    final physRight = physLeft + props.width * savedDpr;
    final physBottom = physTop + props.height * savedDpr;

    bool isPositionValid = false;
    try {
      final displays = await screenRetriever.getAllDisplays();
      isPositionValid = displays.any((display) {
        final pos = display.visiblePosition;
        if (pos == null) return false;
        final sf = (display.scaleFactor ?? 1.0).toDouble();
        final physDisplayBounds = Rect.fromLTWH(
          pos.dx * sf,
          pos.dy * sf,
          display.size.width * sf,
          display.size.height * sf,
        );
        return physDisplayBounds.contains(Offset(physLeft, physTop)) ||
            physDisplayBounds.contains(Offset(physRight, physBottom));
      });
    } catch (_) {}
    if (isPositionValid) {
      await windowManager.setPosition(Offset(
        physLeft / currentDpr,
        physTop / currentDpr,
      ));
    } else {
      await windowManager.setAlignment(Alignment.center);
    }
  }

  Future<void> showAsMainWindow() async {
    // [Gamebox] 主界面恢复直角，避免登录圆角把大窗口裁掉。
    _applyLoginWindowShape(rounded: false);
    final props = globalState.config.windowProps;
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(const Size(380, 400));
    await windowManager.setMaximumSize(const Size(10000, 10000));
    // [Gamebox] 主界面永远用上游默认尺寸 910x620，不读 props。
    // props.width/height 可能是用户拖登录窗时存的 360x420，不应污染主界面。
    await windowManager.setSize(const Size(910, 620));
    await _placeSavedWindow();
  }

  Future<void> showAsLoginWindow() async {
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setResizable(false);
    await windowManager.setMinimumSize(loginSize);
    await windowManager.setMaximumSize(loginSize);
    await windowManager.setSize(loginSize);
    await windowManager.setAlignment(Alignment.center);
    _applyLoginWindowShape(rounded: true);
  }

  void updateMacOSBrightness(Brightness brightness) {}

  Future<void> show() async {
    globalState.handleForeground();
    render?.resume();
    if (await isMinimized) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
    if (!system.isMacOS) {
      await windowManager.setSkipTaskbar(false);
    }
    await globalState.resumeForegroundUpdates();
    await globalState.appController.syncWakelockIfNeeded();
  }

  Future<bool> get isVisible async {
    return await windowManager.isVisible();
  }

  Future<bool> get isMinimized async {
    return await windowManager.isMinimized();
  }

  Future<void> close() async {
    try {
      await trayManager.destroy();
      commonPrint.log('The tray icon has been destroyed.');
    } catch (e) {
      commonPrint.warn('Failed to destroy the tray icon: $e');
    }

    exit(0);
  }

  Future<void> setOpacity(double opacity) async {
    await windowManager.setOpacity(opacity);
  }

  // [Gamebox] 登录切主界面时只藏窗口，不进后台、不摘任务栏。
  Future<void> hideForTransition() {
    return windowManager.hide();
  }

  Future<void> showForTransition() async {
    await windowManager.show();
    await windowManager.focus();
  }

  // [Gamebox] 先挪到屏幕外再显示。窗口刚显示时交换链会先清成白底，这一帧不能让人看见。
  Future<Offset> parkOffscreen() async {
    final origin = await windowManager.getPosition();
    await windowManager.setPosition(const Offset(-16000, -16000));
    return origin;
  }

  Future<void> moveTo(Offset origin) async {
    await windowManager.setPosition(origin);
    await windowManager.focus();
  }

  Future<void> hide() async {
    await windowManager.hide();
    if (!system.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
    await globalState.handleBackground();
  }
}

final window = system.isDesktop ? Window() : null;

// [Gamebox] 只按窗口类名找。标题对不上时按标题找会失败，圆角就不会生效。
HWND? _findGameboxWindow() {
  const names = [
    'GAMEBOX_RUNNER_WIN32_WINDOW',
    'GAMEBOX_DEV_RUNNER_WIN32_WINDOW',
  ];
  for (final name in names) {
    final result = using((arena) => FindWindow(arena.pcwstr(name), PCWSTR(nullptr.cast<Utf16>())));
    final hwnd = result.value;
    if (!hwnd.isNull) return hwnd;
  }
  return null;
}

// [Gamebox] 通知原生窗口：登录小窗收圆，主界面恢复直角。真正裁切在 WM_SIZE 里做。
void _applyLoginWindowShape({required bool rounded}) {
  if (!Platform.isWindows) return;
  final hwnd = _findGameboxWindow();
  if (hwnd == null) return;
  using((arena) {
    final key = arena.pcwstr('GameboxLoginRound');
    final rect = arena<RECT>();
    if (rounded) {
      // [Gamebox] 写一个非 NULL 的 HANDLE 当 truthy 标记。WM_SIZE 里读这个 key 判断要不要切圆角。
      SetProp(hwnd, key, HANDLE(Pointer.fromAddress(1)));
    } else {
      RemoveProp(hwnd, key);
      SetWindowRgn(hwnd, null, true);
      final child = GetWindow(hwnd, GW_CHILD).value;
      if (!child.isNull) {
        SetWindowRgn(child, null, true);
      }
    }
    // [Gamebox] 重新计算边框，登录时铺满窗口，回到主界面再交给原来的边框逻辑。
    SetWindowPos(
      hwnd,
      HWND_TOP,
      0,
      0,
      0,
      0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED,
    );
    if (!GetClientRect(hwnd, rect).value) return;
    PostMessage(
      hwnd,
      WM_SIZE,
      WPARAM(SIZE_RESTORED),
      LPARAM((rect.ref.bottom << 16) | (rect.ref.right & 0xFFFF)),
    );
  });
}
