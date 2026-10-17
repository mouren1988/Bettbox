import 'dart:io';

void main() {
  const content = '''script_template: inno_setup.iss
# [Gamebox] Must differ from upstream Bettbox AppId, otherwise the installer lands in the same dir.
app_id: E7A4C91B-2D58-4F63-9B10-6C8A3D5F12E4
app_name: Gamebox
publisher: appshub.cc
publisher_url: https://github.com/appshubcc/Bettbox
# [Gamebox] Installer display name and main exe. Kernel exe is installed as GameboxCore.exe.
display_name: Gamebox
executable_name: Gamebox.exe
output_base_file_name: Gamebox.exe
setup_icon_file: ..\\windows\\runner\\resources\\app_icon.ico
locales:
  - lang: zh
    file: ..\\windows\\packaging\\exe\\ChineseSimplified.isl
  - lang: en
privileges_required: admin
# [Gamebox] Desktop shortcut enabled by default (inno_setup.iss no longer toggles unchecked/checkedonce).
create_desktop_icon: true
''';
  File('windows/packaging/exe/make_config.yaml').writeAsStringSync(content, encoding: const SystemEncoding());
  print('OK ${File('windows/packaging/exe/make_config.yaml').lengthSync()} bytes');
}
