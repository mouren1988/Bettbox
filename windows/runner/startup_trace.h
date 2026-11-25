#ifndef RUNNER_STARTUP_TRACE_H_
#define RUNNER_STARTUP_TRACE_H_

// [Gamebox] 黑屏排查：把启动关键步骤追加写到配置目录
// %APPDATA%\com.appshub\Gamebox\startup.log。
// Dart 侧往同一个文件追加，客户机只需回传这一个文件。
void StartupTraceBegin();
void StartupTrace(const char* format, ...);

#endif  // RUNNER_STARTUP_TRACE_H_
