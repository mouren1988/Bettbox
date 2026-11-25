import 'dart:io';

// [Gamebox] 黑屏排查：与原生 startup_trace.cpp 写同一个文件
// %APPDATA%\com.appshub\Gamebox\startup.log，客户机只需回传这一个文件。
void startupTrace(String message) {
  if (!Platform.isWindows) return;
  try {
    final base = Platform.environment['APPDATA'];
    if (base == null || base.isEmpty) return;
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    final time =
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.$ms';
    File('$base\\com.appshub\\Gamebox\\startup.log').writeAsStringSync(
      '$time [dart] $message\r\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}
