import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// [Gamebox] 首页默认布局回归测试。
///
/// 背景：Android 默认布局在 3.18 / 3.19 / 3.20 连续排错三次，
/// 根因是 masonry 瀑布流的实际落位由卡片**宽高**决定，光看顺序列表看不出来。
/// 这里把「顺序 + 宽度」一起钉死，防止以后再无声改错。
void main() {
  group('Android 默认布局', () {
    test('顺序与用户实机 config.json 一致', () {
      expect(defaultAndroidDashboardWidgets, const [
        DashboardWidget.networkSpeedSmall,
        DashboardWidget.userProfile,
        DashboardWidget.trafficUsage,
        DashboardWidget.networkDetection,
        DashboardWidget.intranetIp,
        DashboardWidget.mediaUnlockSmall,
        DashboardWidget.memoryInfo,
        DashboardWidget.connectionsCount,
        DashboardWidget.startButton,
      ]);
    });

    test('首行必须是单宽 networkSpeedSmall，不能是双宽 networkSpeed', () {
      // networkSpeed 是 8 列(整行独占)，放首行会把 userProfile 挤到下一行、
      // 右列留空 —— 这正是 3.18/3.19/3.20 反复排错的根因。
      expect(
        DashboardWidget.networkSpeed.nativeSize,
        DashboardTileSize.large,
      );
      expect(
        DashboardWidget.networkSpeedSmall.nativeSize,
        DashboardTileSize.small,
      );
      expect(
        defaultAndroidDashboardWidgets.first,
        DashboardWidget.networkSpeedSmall,
        reason: '首行用双宽卡会让整张首页错位',
      );
    });

    test('不存在双宽卡；高卡只有流量统计和解锁检测', () {
      // trafficUsage / mediaUnlockSmall 的 nativeSize 是 tall(高卡)，
      // 属预期内的例外（详见 lib/enum/enum.dart nativeSize）。
      final wide = defaultAndroidDashboardWidgets
          .where((w) => w.nativeSize == DashboardTileSize.large)
          .toList();
      expect(wide, isEmpty, reason: '不应存在整行独占的双宽卡');

      final tall = defaultAndroidDashboardWidgets
          .where((w) => w.nativeSize == DashboardTileSize.tall)
          .map((w) => w.name)
          .toList();
      expect(tall, ['trafficUsage', 'mediaUnlockSmall']);
    });

    test('卡片数量与唯一性', () {
      expect(defaultAndroidDashboardWidgets.length, 9);
      expect(
        defaultAndroidDashboardWidgets.toSet().length,
        defaultAndroidDashboardWidgets.length,
        reason: '不允许重复卡片',
      );
    });

    test('所有卡片均支持 Android 平台', () {
      for (final w in defaultAndroidDashboardWidgets) {
        expect(
          w.platforms,
          contains(SupportPlatform.Android),
          reason: '${w.name} 不支持 Android，会被 dashboard 过滤掉',
        );
      }
    });
  });

  group('桌面端默认布局', () {
    test('桌面端保持 networkSpeed(双宽) 打头，不受 Android 改动影响', () {
      expect(defaultDashboardWidgets, const [
        DashboardWidget.networkSpeed,
        DashboardWidget.userProfile,
        DashboardWidget.trafficUsage,
        DashboardWidget.networkDetection,
        DashboardWidget.intranetIp,
        DashboardWidget.mediaUnlockSmall,
        DashboardWidget.memoryInfo,
        DashboardWidget.connectionsCount,
        DashboardWidget.startButton,
      ]);
    });
  });
}