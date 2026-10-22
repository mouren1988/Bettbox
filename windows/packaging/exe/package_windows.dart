// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:liquid_engine/liquid_engine.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('arch', allowed: ['amd64', 'arm64'], mandatory: true)
    ..addFlag('compatible', defaultsTo: false)
    ..addOption('env', defaultsTo: 'pre')
    ..addFlag('dev', defaultsTo: false)
    ..addFlag('portable', defaultsTo: null)
    ..addFlag('installer', defaultsTo: true);

  final args = parser.parse(arguments);
  final arch = args['arch'] as String;
  final compatible = args['compatible'] as bool;
  final isDev = args['dev'] as bool;
  final makePortable =
      (args['portable'] as bool?) ?? (compatible && arch == 'amd64');
  final makeInstaller = args['installer'] as bool;

  final desc = compatible ? '$arch-compatible' : arch;

  // 1. Get version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found.');
    exit(1);
  }
  final pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(
    r'^version:\s*([^\s+]+)',
    multiLine: true,
  ).firstMatch(pubspecContent);
  if (versionMatch == null) {
    print('Error: Could not find version in pubspec.yaml.');
    exit(1);
  }
  final appVersion = versionMatch.group(1)!;
  print('App Version: $appVersion');

  // 2. Parse make_config.yaml
  final configFile = File('windows/packaging/exe/make_config.yaml');
  if (!configFile.existsSync()) {
    print('Error: make_config.yaml not found.');
    exit(1);
  }
  final configContent = configFile.readAsStringSync();
  final makeConfig = loadYaml(configContent) as YamlMap;

  final displayName = makeConfig['display_name'] as String? ?? 'Gamebox';
  final productName = makeConfig['app_name'] as String? ?? 'Gamebox';

  final outputBaseName = '$displayName-$appVersion-windows-$desc-setup';

  // 3. Define directories
  final buildDirName = arch == 'arm64' ? 'arm64' : 'x64';
  final sourceDir = path.absolute('build/windows/$buildDirName/runner/Release');
  print('Source Directory: $sourceDir');
  if (!Directory(sourceDir).existsSync()) {
    print(
      'Error: Source directory $sourceDir does not exist. Run flutter build first.',
    );
    exit(1);
  }

  // 4. Map variables for Inno Setup template
// [Gamebox] 用 productName 参数化，不再硬编码 Bettbox。
  // 注意 helperServiceName 用的是 display 形式（'$productName Helper'），
  // 而上游 v1.19.7 是 'BettboxHelperService'（技术键，无空格）。
  // 两者都要保留：服务名要与 windows/runner 里注册的一致，
  // 命名空间 (productName) 决定实际 Win32 服务/管道标识符。
  final coreExecutableName =
      isDev ? '${productName}DevCore.exe' : '${productName}Core.exe';
  final helperExecutableName = isDev
      ? '${productName}DevHelperService.exe'
      : '${productName}HelperService.exe';
  final helperServiceName = isDev
      ? '$productName Dev Helper'
      : '$productName Helper';
  final helperPipeName =
      isDev
      ? r'\\.\pipe\' + productName + r'Dev.Helper'
      : r'\\.\pipe\' + productName + r'.Helper';
  final taskName = isDev ? '$displayName Dev' : displayName;
  // Format locales - resolve file paths to absolute to avoid Inno Setup relative path issues
  final packagingDir = path.absolute('windows/packaging/exe');
  final locales = [];
  if (makeConfig['locales'] != null) {
    for (var locale in makeConfig['locales']) {
      final fileVal = locale['file'] as String?;
      locales.add({
        'lang': locale['lang'],
        // Extract just the filename and resolve against the packaging directory
        'file': fileVal != null
            ? path.join(packagingDir, path.basename(fileVal))
            : null,
      });
    }
  }

  final variables = {
    'APP_ID': makeConfig['app_id'],
    'APP_NAME': makeConfig['app_name'],
    'APP_VERSION': appVersion,
    'EXECUTABLE_NAME': makeConfig['executable_name'] ?? 'Gamebox.exe',
    'DISPLAY_NAME': makeConfig['display_name'] ?? 'Gamebox',
    'PUBLISHER_NAME': makeConfig['publisher'] ?? 'appshub.cc',
    'ARCH': arch == 'arm64' ? 'arm64' : 'x64',
// [Gamebox] 仓库指向 fork（见 §3.6），display_name 兜底也是 Gamebox。
    //   上游用的是 '\${makeConfig['display_name'] ?? 'Bettbox'}'，
    //   这里改用已解析好的 $displayName（同样的语义，少一次 map 查找）。
    'PUBLISHER_URL':
        makeConfig['publisher_url'] ?? 'https://github.com/appshubcc/Gamebox',
    'CREATE_DESKTOP_ICON': true,
    'LAUNCH_AT_STARTUP': true,
    'INSTALL_DIR_NAME': '{autopf64}\\$displayName',
    'SOURCE_DIR': sourceDir,
    'OUTPUT_BASE_FILENAME': outputBaseName,
    'LOCALES': locales,
    'SETUP_ICON_FILE': path.absolute('windows/runner/resources/app_icon.ico'),
    'PRIVILEGES_REQUIRED': makeConfig['privileges_required'] ?? 'admin',
    'CORE_EXECUTABLE_NAME': coreExecutableName,
    'HELPER_EXECUTABLE_NAME': helperExecutableName,
    'HELPER_SERVICE_NAME': helperServiceName,
    'HELPER_PIPE_NAME': helperPipeName,
    'TASK_NAME': taskName,
  };

  // 5. Render Liquid template
  final templateFile = File('windows/packaging/exe/inno_setup.iss');
  if (!templateFile.existsSync()) {
    print('Error: inno_setup.iss template not found.');
    exit(1);
  }
  final templateContent = templateFile.readAsStringSync();

  final context = Context.create();
  context.variables = variables;

  final template = Template.parse(context, Source.fromString(templateContent));

  final renderedContent = '\uFEFF${await template.render(context)}';
  final tempIssFile = File('windows/packaging/exe/temp_setup.iss');
  tempIssFile.writeAsBytesSync(utf8.encode(renderedContent));
  print('Generated temp_setup.iss');

  // 6. Run ISCC.exe
  if (makeInstaller) {
    final isccPath = 'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe';
    if (!File(isccPath).existsSync()) {
      print('Error: Inno Setup 6 is not installed at $isccPath');
      tempIssFile.deleteSync();
      exit(1);
    }

    print('Running ISCC.exe...');
    final processResult = await Process.run(isccPath, [tempIssFile.path]);
    print(processResult.stdout);
    print(processResult.stderr);

    // Clean up temp ISS file
    if (tempIssFile.existsSync()) {
      tempIssFile.deleteSync();
    }

    if (processResult.exitCode != 0) {
      print('Error: ISCC.exe compilation failed.');
      exit(processResult.exitCode);
    }

    // 7. Move generated installer to dist/
    final generatedInstallerPath = path.join(
      'windows/packaging/exe',
      '$outputBaseName.exe',
    );
    final generatedInstallerFile = File(generatedInstallerPath);
    if (!generatedInstallerFile.existsSync()) {
      print('Error: Generated installer not found at $generatedInstallerPath');
      exit(1);
    }

    final distDir = Directory('dist');
    if (!distDir.existsSync()) {
      distDir.createSync(recursive: true);
    }

    final targetInstallerPath = path.join('dist', '$outputBaseName.exe');
    generatedInstallerFile.renameSync(targetInstallerPath);
    print(
      'Successfully generated and moved installer to: $targetInstallerPath',
    );
  } else {
    if (tempIssFile.existsSync()) {
      tempIssFile.deleteSync();
    }
  }

  if (makePortable) {
    final distDir = Directory('dist');
    if (!distDir.existsSync()) {
      distDir.createSync(recursive: true);
    }

    final portableDir = Directory(path.join(sourceDir, 'portable'));
    if (!portableDir.existsSync()) {
      portableDir.createSync(recursive: true);
    }
    final keepFile = File(path.join(portableDir.path, '.keep'));
    if (!keepFile.existsSync()) {
      keepFile.writeAsStringSync('');
    }

    final cleanBatSource = File('windows/packaging/portable/clean.bat');
    final cleanBatDest = File(path.join(sourceDir, 'clean.bat'));
    if (cleanBatSource.existsSync()) {
      cleanBatSource.copySync(cleanBatDest.path);
    }

// [Gamebox] 用 $displayName 参数化（产物名 Gamebox-*-portable.zip），不硬编码 Bettbox。
    final portableOutputBaseName =
        '$displayName-$appVersion-windows-$desc-portable.zip';
    final targetPortableZipPath = path.join('dist', portableOutputBaseName);
    final targetPortableFile = File(targetPortableZipPath);
    if (targetPortableFile.existsSync()) {
      targetPortableFile.deleteSync();
    }

    print('Creating portable zip: $targetPortableZipPath');
    try {
      final zipFileEncoder = ZipFileEncoder()..create(targetPortableZipPath);
      // [Gamebox] 兜底名改为 Gamebox，否则 make_config.yaml 缺 display_name 时
      // 解压出来会是 Bettbox/ 目录（上游 v1.19.7 遗留的硬编码）。
      final rootName = makeConfig['display_name'] ?? displayName;
      final entries = Directory(
        sourceDir,
      ).listSync(recursive: true, followLinks: true);
      for (final entry in entries.whereType<File>()) {
        final relative = path
            .relative(entry.path, from: sourceDir)
            .replaceAll(r'\', '/');
        await zipFileEncoder.addFile(entry, '$rootName/$relative');
      }
      await zipFileEncoder.close();
      print('Successfully generated portable zip: $targetPortableZipPath');
    } finally {
      if (portableDir.existsSync()) {
        portableDir.deleteSync(recursive: true);
      }
      if (cleanBatDest.existsSync()) {
        cleanBatDest.deleteSync();
      }
    }
  }
}
