import 'package:bett_box/enum/enum.dart';
import 'package:bett_box/views/dashboard/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('尺寸表只对同组的主组件生效，无效值回退到原有尺寸', () {
    const sizes = {'networkSpeed': 'wide', 'memoryInfo': 'large'};
    expect(
      resolveDashboardSize(DashboardWidget.networkSpeed, sizes),
      DashboardTileSize.wide,
    );
    expect(
      resolveDashboardSize(DashboardWidget.networkSpeedSmall, sizes),
      DashboardTileSize.small,
    );
    expect(
      resolveDashboardSize(DashboardWidget.memoryInfo, sizes),
      DashboardTileSize.small,
    );
    expect(
      resolveDashboardSize(DashboardWidget.memoryInfo, const {
        'memoryInfo': 'tall',
      }),
      DashboardTileSize.tall,
    );
    expect(
      resolveDashboardSize(DashboardWidget.trafficUsage, const {}),
      DashboardTileSize.tall,
    );
  });

  test('原有尺寸沿用原组件，新尺寸才使用新排版', () {
    final small = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.small,
    ));
    expect(small, isA<NetworkSpeedSmall>());

    final large = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.large,
    ));
    expect(large, isA<NetworkSpeed>());
    expect((large as NetworkSpeed).size, isNull);

    final wide = buildDashboardTile((
      widget: DashboardWidget.networkSpeed,
      size: DashboardTileSize.wide,
    ));
    expect((wide as NetworkSpeed).size, DashboardTileSize.wide);

    final memory = buildDashboardTile((
      widget: DashboardWidget.memoryInfo,
      size: DashboardTileSize.small,
    ));
    expect((memory as MemoryInfo).size, isNull);

    final tallMemory = buildDashboardTile((
      widget: DashboardWidget.memoryInfo,
      size: DashboardTileSize.tall,
    ));
    expect((tallMemory as MemoryInfo).size, DashboardTileSize.tall);

    // [Gamebox] 出站模式卡片已永久删除（见 §3.7），改用 trafficUsage
    // 验证 tall 尺寸仍然可用。
    final traffic = buildDashboardTile((
      widget: DashboardWidget.trafficUsage,
      size: DashboardTileSize.tall,
    ));
    expect(traffic, isA<TrafficUsage>());
  });
}
