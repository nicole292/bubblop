import 'package:flutter/widgets.dart';

import '../game/palette.dart';
import '../services/settings.dart';

/// Keeps [Palette.dark] in step with the Light / Dark / Auto setting and,
/// on Auto, with the phone's own dark mode. Colours are read from [Palette]
/// while building and painting, so a switch rebuilds and repaints every
/// widget below (the game itself repaints every frame).
class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key, required this.settings, required this.child});
  final Settings settings;
  final Widget child;

  /// Whether [choice] means dark right now, given the phone's [platform] look.
  static bool isDark(ThemeChoice choice, Brightness platform) => switch (choice) {
    ThemeChoice.dark => true,
    ThemeChoice.light => false,
    ThemeChoice.auto => platform == Brightness.dark,
  };

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.settings.addListener(_update);
    Palette.dark = _wanted;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.settings.removeListener(_update);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _update();

  bool get _wanted =>
      ThemeSwitch.isDark(widget.settings.theme, WidgetsBinding.instance.platformDispatcher.platformBrightness);

  void _update() {
    final dark = _wanted;
    if (dark == Palette.dark || !mounted) return;
    Palette.dark = dark;
    void refresh(Element e) {
      e.markNeedsBuild();
      e.renderObject?.markNeedsPaint();
      e.visitChildren(refresh);
    }

    context.visitChildElements(refresh);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
