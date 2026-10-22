// [Gamebox] Outbound-mode widgets PERMANENTLY DISABLED.
//
// Removed from DashboardWidget enum in lib/enum/enum.dart.
// Removed from widgets.dart barrel export.
//
// This file is kept only as a stub so that any stale `import
// 'outbound_mode.dart'` (e.g. in a branch the user has not yet rebased)
// still compiles. Trying to instantiate the widget throws.
//
// The mihomo core still honours `mode: global|rule|direct` in clash
// config; the user can still switch mode from the system tray menu or
// from the Yacd/Meta web panel, but not from the Gamebox home dashboard.

import 'package:flutter/widgets.dart';

class OutboundMode extends StatelessWidget {
  const OutboundMode({super.key});

  @override
  Widget build(BuildContext context) {
    throw UnsupportedError(
      '[Gamebox] OutboundMode widget has been permanently removed. '
      'Use the system tray menu or web panel to change proxy mode.',
    );
  }
}

class OutboundModeV2 extends StatelessWidget {
  const OutboundModeV2({super.key});

  @override
  Widget build(BuildContext context) {
throw UnsupportedError(
      '[Gamebox] OutboundModeV2 widget has been permanently removed. '
      'Use the system tray menu or web panel to change proxy mode.',
    );
  }
}
