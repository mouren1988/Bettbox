#include "startup_trace.h"

#include <windows.h>

#include <d3d11.h>
#include <dwmapi.h>
#include <dxgi.h>
#include <shlobj_core.h>

#include <cstdarg>
#include <cstdio>
#include <string>

namespace {

std::wstring TracePath() {
  wchar_t base[MAX_PATH];
  const DWORD len = ::GetEnvironmentVariableW(L"APPDATA", base, MAX_PATH);
  if (len == 0 || len >= MAX_PATH) {
    return L"";
  }
  std::wstring dir(base);
  dir += L"\\com.appshub\\Gamebox";
  ::SHCreateDirectoryExW(nullptr, dir.c_str(), nullptr);
  return dir + L"\\startup.log";
}

std::string Narrow(const wchar_t* text) {
  if (!text) {
    return "";
  }
  const int size =
      ::WideCharToMultiByte(CP_UTF8, 0, text, -1, nullptr, 0, nullptr, nullptr);
  if (size <= 1) {
    return "";
  }
  std::string out(size - 1, '\0');
  ::WideCharToMultiByte(CP_UTF8, 0, text, -1, out.data(), size, nullptr,
                        nullptr);
  return out;
}

void AppendLine(const std::string& line) {
  const std::wstring path = TracePath();
  if (path.empty()) {
    return;
  }
  HANDLE file = ::CreateFileW(path.c_str(), FILE_APPEND_DATA,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                              OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }
  SYSTEMTIME now;
  ::GetLocalTime(&now);
  char prefix[64];
  std::snprintf(prefix, sizeof(prefix), "%02d:%02d:%02d.%03d [native] ",
                now.wHour, now.wMinute, now.wSecond, now.wMilliseconds);
  const std::string full = prefix + line + "\r\n";
  DWORD written = 0;
  ::WriteFile(file, full.data(), static_cast<DWORD>(full.size()), &written,
              nullptr);
  ::CloseHandle(file);
}

const char* FeatureLevelName(D3D_FEATURE_LEVEL level) {
  switch (level) {
    case D3D_FEATURE_LEVEL_12_1: return "12_1";
    case D3D_FEATURE_LEVEL_12_0: return "12_0";
    case D3D_FEATURE_LEVEL_11_1: return "11_1";
    case D3D_FEATURE_LEVEL_11_0: return "11_0";
    case D3D_FEATURE_LEVEL_10_1: return "10_1";
    case D3D_FEATURE_LEVEL_10_0: return "10_0";
    case D3D_FEATURE_LEVEL_9_3: return "9_3";
    case D3D_FEATURE_LEVEL_9_2: return "9_2";
    case D3D_FEATURE_LEVEL_9_1: return "9_1";
    default: return "unknown";
  }
}

void TraceOsVersion() {
  using RtlGetVersionFn = LONG(WINAPI*)(PRTL_OSVERSIONINFOW);
  HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  auto fn = ntdll ? reinterpret_cast<RtlGetVersionFn>(
                        ::GetProcAddress(ntdll, "RtlGetVersion"))
                  : nullptr;
  RTL_OSVERSIONINFOW info{};
  info.dwOSVersionInfoSize = sizeof(info);
  if (fn && fn(&info) == 0) {
    StartupTrace("os=%lu.%lu.%lu", info.dwMajorVersion, info.dwMinorVersion,
                 info.dwBuildNumber);
  }
  // 右键「兼容模式」运行时系统会设置 __COMPAT_LAYER，os 版本也会被伪装。
  wchar_t layer[256];
  const DWORD n = ::GetEnvironmentVariableW(L"__COMPAT_LAYER", layer, 256);
  StartupTrace("compat_layer=%s",
               (n > 0 && n < 256) ? Narrow(layer).c_str() : "");
  BOOL composition = FALSE;
  ::DwmIsCompositionEnabled(&composition);
  StartupTrace("dwm_composition=%d", composition ? 1 : 0);
}

void TraceAdapters() {
  IDXGIFactory1* factory = nullptr;
  if (FAILED(::CreateDXGIFactory1(__uuidof(IDXGIFactory1),
                                  reinterpret_cast<void**>(&factory)))) {
    StartupTrace("dxgi_factory=failed");
    return;
  }
  IDXGIAdapter1* adapter = nullptr;
  for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND;
       ++i) {
    DXGI_ADAPTER_DESC1 desc{};
    adapter->GetDesc1(&desc);
    StartupTrace("adapter[%u]=%s vendor=0x%04X device=0x%04X vram=%lluMB flags=%u",
                 i, Narrow(desc.Description).c_str(), desc.VendorId,
                 desc.DeviceId,
                 static_cast<unsigned long long>(desc.DedicatedVideoMemory >> 20),
                 desc.Flags);
    adapter->Release();
  }
  factory->Release();
}

void TraceD3D11() {
  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  D3D_FEATURE_LEVEL level = D3D_FEATURE_LEVEL_9_1;
  const HRESULT hr = ::D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, nullptr, 0,
      D3D11_SDK_VERSION, &device, &level, &context);
  StartupTrace("d3d11_hardware hr=0x%08lX feature_level=%s",
               static_cast<unsigned long>(hr),
               SUCCEEDED(hr) ? FeatureLevelName(level) : "-");
  if (context) context->Release();
  if (device) device->Release();
}

}  // namespace

void StartupTrace(const char* format, ...) {
  char buffer[1024];
  va_list args;
  va_start(args, format);
  std::vsnprintf(buffer, sizeof(buffer), format, args);
  va_end(args);
  AppendLine(buffer);
}

void StartupTraceBegin() {
  AppendLine("======== Gamebox start pid=" +
             std::to_string(::GetCurrentProcessId()) + " ========");
  TraceOsVersion();
  TraceAdapters();
  TraceD3D11();
}
