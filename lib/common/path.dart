import 'dart:async';
import 'dart:io';

import 'package:bett_box/common/common.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AppPath {
  static AppPath? _instance;
  Completer<Directory> dataDir = Completer();
  Completer<Directory> downloadDir = Completer();
  Completer<Directory> tempDir = Completer();
  late String appDirPath;
  late final bool isPortable;

  String? _resolvedDataDirPath;

  AppPath._internal() {
    appDirPath = join(dirname(Platform.resolvedExecutable));
    final portableDir = Directory(join(appDirPath, 'portable'));
    isPortable = system.isWindows && portableDir.existsSync();
    if (isPortable) {
      _resolvedDataDirPath = portableDir.path;
      dataDir.complete(portableDir);
      var portableTempDir = Directory(join(portableDir.path, 'temp'));
      try {
        portableTempDir.createSync(recursive: true);
      } catch (_) {
        portableTempDir = Directory.systemTemp;
      }
      tempDir.complete(portableTempDir);
    } else {
      getApplicationSupportDirectory().then((value) {
        if (system.isWindows && AppIdentity.isDev) {
          final dir = Directory(
            join(value.parent.path, AppIdentity.dataDirName),
          );
          _resolvedDataDirPath = dir.path;
          dataDir.complete(dir);
        } else {
          _resolvedDataDirPath = value.path;
          dataDir.complete(value);
        }
      });
      getTemporaryDirectory().then((value) {
        tempDir.complete(value);
      });
    }
    _resolveDownloadDir();
  }

  // [Gamebox] 解析「下载目录」，并保证**一定成功**。
  //
  // 背景：getDownloadsDirectory() 只有 macOS 平台实现，其它平台
  // (Windows / Linux / Android) 的 MethodChannelPathProvider.getDownloadsPath()
  // 会直接抛 UnsupportedError('Functionality only available on macOS')。
  // 原代码无条件调用且没接错误，导致两个问题：
  //   1. 非 macOS 上后台一直抛未捕获异常；
  //   2. downloadDir 这个 Completer 永远不 complete，而 picker 用
  //      `await appPath.downloadDirPath` 决定文件对话框的默认目录，
  //      一旦走到那里就会永久等待 → 对话框卡住不出。
  //
  // 现在按平台取值，并加兜底，保证这个 Completer 一定会完成：
  //   - macOS   : 真正的「下载」目录
  //   - Windows : %USERPROFILE%\Downloads（可被 OneDrive 重定向，不存在就退回文档目录）
  //   - 其它    : 文档 / 应用支持目录
  Future<void> _resolveDownloadDir() async {
    Directory? resolved;
    if (system.isMacOS) {
      try {
        resolved = await getDownloadsDirectory();
      } catch (_) {
        // 落到下面的兜底。
      }
    }
    resolved ??= await _fallbackDownloadDir().timeout(
      // 通道无响应时不能把调用方一起拖死。
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
    // 兜底的兜底：systemTemp 一定存在。
    resolved ??= Directory.systemTemp;
    if (!resolved.existsSync()) resolved = Directory.systemTemp;
    if (!downloadDir.isCompleted) downloadDir.complete(resolved);
  }

  Future<Directory?> _fallbackDownloadDir() async {
    try {
      if (system.isWindows) {
        final home = Platform.environment['USERPROFILE'];
        if (home != null && home.isNotEmpty) {
          final dir = Directory(join(home, 'Downloads'));
          // 下载目录常被重定向到 OneDrive 等位置，只在确实存在时才用它。
          if (dir.existsSync()) return dir;
        }
      }
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  factory AppPath() {
    _instance ??= AppPath._internal();
    return _instance!;
  }

  String get executableExtension {
    return system.isWindows ? '.exe' : '';
  }

  String get executableDirPath {
    final currentExecutablePath = Platform.resolvedExecutable;
    return dirname(currentExecutablePath);
  }

  bool get isAppImage =>
      Platform.isLinux &&
      (Platform.environment.containsKey('APPIMAGE') ||
          executableDirPath.contains('/.mount_'));

  String get _linuxUserDataDirPath {
    if (_resolvedDataDirPath != null) return _resolvedDataDirPath!;
    final xdgData = Platform.environment['XDG_DATA_HOME'];
    final baseDir = (xdgData != null && xdgData.isNotEmpty)
        ? xdgData
        : join(Platform.environment['HOME'] ?? '', '.local', 'share');
    return join(
      baseDir,
      AppIdentity.isDev
          ? '${AppIdentity.packageId}.dev'
          : AppIdentity.packageId,
    );
  }

  String get bundledCorePath {
    final devWorkspacePath = _devWorkspacePath;
    if (devWorkspacePath != null) {
      final corePath = join(
        devWorkspacePath,
        'libclash',
        'windows',
        '${AppIdentity.coreExecutableName}$executableExtension',
      );
      if (File(corePath).existsSync()) {
        return corePath;
      }
    }

    return join(
      executableDirPath,
      '${AppIdentity.coreExecutableName}$executableExtension',
    );
  }

  String get corePath {
    if (isAppImage) {
      return join(
        _linuxUserDataDirPath,
        'core',
        '${AppIdentity.coreExecutableName}$executableExtension',
      );
    }
    return bundledCorePath;
  }

  Future<void> ensureAppImageCoreSynced() async {
    if (!isAppImage) return;

    final bundled = File(bundledCorePath);
    if (!bundled.existsSync()) return;

    final external = File(corePath);
    final stampFile = File(join(external.parent.path, '.core_stamp'));

    final bundledStat = bundled.statSync();
    final currentStamp =
        '${bundledStat.size}_${bundledStat.modified.millisecondsSinceEpoch}';

    if (external.existsSync() && stampFile.existsSync()) {
      try {
        final recordedStamp = stampFile.readAsStringSync().trim();
        if (recordedStamp == currentStamp) {
          return;
        }
      } catch (_) {}
    }

    try {
      if (!external.parent.existsSync()) {
        external.parent.createSync(recursive: true);
      }
      final tempFile = File('${external.path}.tmp');
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
      bundled.copySync(tempFile.path);
      tempFile.renameSync(external.path);
      Process.runSync('chmod', ['0755', external.path]);
      stampFile.writeAsStringSync(currentStamp);
    } catch (e) {
      commonPrint.warn('Failed to sync AppImage core: $e');
    }
  }

  String get helperPath {
    final devWorkspacePath = _devWorkspacePath;
    if (devWorkspacePath != null) {
      final helperPath = join(
        devWorkspacePath,
        'libclash',
        'windows',
        '$appHelperService$executableExtension',
      );
      if (File(helperPath).existsSync()) {
        return helperPath;
      }
    }

    return join(executableDirPath, '$appHelperService$executableExtension');
  }

  String? get _devWorkspacePath {
    if (!system.isWindows || !AppIdentity.isDev) return null;
    var directory = Directory(executableDirPath);
    for (var depth = 0; depth < 8; depth++) {
      final pubspecPath = join(directory.path, 'pubspec.yaml');
      if (File(pubspecPath).existsSync()) return directory.path;

      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }

    return null;
  }

  Future<String> get downloadDirPath async {
    // [Gamebox] _resolveDownloadDir() 保证一定会 complete，这里再加一道
    // 超时兜底：文件选择框的默认目录不值得让它把调用方永远挂住。
    final directory = await downloadDir.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => Directory.systemTemp,
    );
    return directory.path;
  }

  Future<String> get homeDirPath async {
    final directory = await dataDir.future;
    return directory.path;
  }

  Future<String> get lockFilePath async {
    final directory = await dataDir.future;
    return join(directory.path, '${AppIdentity.dataDirName}.lock');
  }

  Future<String> get controlSocketPath async {
    final directory = await dataDir.future;
    return join(directory.path, '${AppIdentity.dataDirName}.control.sock');
  }

  Future<String> get controlPortFilePath async {
    final directory = await dataDir.future;
    return join(directory.path, '${AppIdentity.dataDirName}.control.port');
  }

  Future<String> get sharedPreferencesPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'shared_preferences.json');
  }

  Future<String> get appConfigPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'config.json');
  }

  Future<String> get ipCacheFilePath async {
    final tempDirectory = await tempPath;
    return join(tempDirectory, 'ip_cache.json');
  }

  Future<String> get speedTestPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'speed_test.json');
  }

  Future<String> get toolHistoryPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'toolbox_history.json');
  }

  Future<String> get helperAuthKeyPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'helper_auth.key');
  }

  Future<String> get profilesPath async {
    final directory = await dataDir.future;
    return join(directory.path, profilesDirectoryName);
  }

  Future<String> getProfilePath(String id) async {
    final directory = await profilesPath;
    return join(directory, '$id.yaml');
  }

  Future<String> getScriptPath(String id) async {
    final directory = await dataDir.future;
    return join(directory.path, 'scripts', '${basename(id)}.js');
  }

  Future<String> getProvidersDirPath(String id) async {
    final directory = await profilesPath;
    return join(directory, 'providers', id);
  }

  Future<String> getProvidersFilePath(
    String id,
    String type,
    String url,
  ) async {
    final directory = await profilesPath;
    return join(directory, 'providers', id, type, url.toMd5());
  }

  Future<String> get tempPath async {
    final directory = await tempDir.future;
    return directory.path;
  }

  Future<String> get relayPath async {
    final directory = Directory(join(await homeDirPath, 'relay'));
    await directory.create(recursive: true);
    return directory.path;
  }

  Future<String> get uiPath async {
    final directory = await dataDir.future;
    return join(directory.path, 'ui');
  }
}

final appPath = AppPath();
