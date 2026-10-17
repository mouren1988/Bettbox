import 'dart:io';
import 'dart:convert';

void main() {
  final files = [
    'windows/packaging/exe/inno_setup.iss',
  ];
  for (final p in files) {
    final f = File(p);
    final bytes = f.readAsBytesSync();
    // Detect BOM / encoding
    final isUtf16LeBom = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE;
    final isUtf8Bom = bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
    late String content;
    String fromEnc;
    if (isUtf16LeBom) {
      // dart:convert provides utf8; for utf-16-LE use iconv-style manual decode:
      // each code unit is 2 bytes little-endian. Skip BOM.
      final body = bytes.sublist(2);
      final units = <int>[];
      for (var i = 0; i + 1 < body.length; i += 2) {
        units.add(body[i] | (body[i + 1] << 8));
      }
      content = String.fromCharCodes(units);
      fromEnc = 'utf-16le';
    } else if (isUtf8Bom) {
      content = utf8.decode(bytes.sublist(3));
      fromEnc = 'utf-8-bom';
    } else {
      try {
        content = utf8.decode(bytes);
        fromEnc = 'utf-8';
      } catch (e) {
        // Fallback to GBK (cp936) - decode via SystemEncoding then encode to utf8
        // dart:io SystemEncoding on Windows CN is GBK; we'll just write as GBK bytes
        // (Inno Setup itself supports GBK input). Don't convert.
        print('SKIP cannot decode as utf-8: $p  ($e)');
        continue;
      }
    }
    // Normalize line endings to LF (Inno Setup accepts both, but LF is safer)
    content = content.replaceAll('\r\n', '\n');
    f.writeAsStringSync(content, encoding: utf8, flush: true);
    print('OK  $p  $fromEnc  ->  utf-8  (${content.length} chars, ${f.lengthSync()} bytes)');
  }
}
