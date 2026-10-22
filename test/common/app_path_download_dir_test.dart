import 'dart:io';

import 'package:bett_box/common/common.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

// getDownloadsDirectory() 只有 macOS 平台实现，其它平台
// (Windows / Linux / Android) 的 getDownloadsPath() 直接抛
// UnsupportedError('Functionality only available on macOS')。
// AppPath 构造时无条件调它，且没接错误 → downloadDir 永远不 complete，
// 而 picker 用 `await appPath.downloadDirPath` 当文件对话框默认目录，
// 走到那里就永久等待、对话框卡住。
class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root, {this.downloadsThrows = false});

  final String root;
  final bool downloadsThrows;

  @override
  Future<String?> getTemporaryPath() async => root;

  @override
  Future<String?> getApplicationSupportPath() async => root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;

  @override
  Future<String?> getDownloadsPath() async {
    if (downloadsThrows) {
      throw UnsupportedError('Functionality only available on macOS');
    }
    return root;
  }

  @override
  Future<String?> getApplicationCachePath() async => root;

  @override
  Future<String?> getLibraryPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('gamebox_path_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('downloadDirPath 一定能拿到值（Windows 上不卡死）', () async {
    // 模拟 Windows：getDownloadsPath 直接抛（上游真实行为）。
    PathProviderPlatform.instance = _FakePathProvider(
      tmp.path,
      downloadsThrows: true,
    );

    // AppPath 是单例，这里只验证 getter 不会永久挂住。
    // 显式给一个较短超时，若 AppPath 没兜底就会超时失败。
    final path = await appPath.downloadDirPath.timeout(
      const Duration(seconds: 6),
    );
    expect(path, isNotEmpty);
    expect(Directory(path).existsSync(), isTrue);
  }, timeout: const Timeout(Duration(seconds: 20)));
}