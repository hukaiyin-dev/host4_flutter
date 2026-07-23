import 'package:flutter/material.dart';

extension DemoThemeContext on BuildContext {
  DemoTheme get host4Theme => DemoTheme(Theme.of(this).colorScheme);
}

class DemoTheme {
  DemoTheme(ColorScheme scheme)
    : colors = DemoColors(scheme),
      spacing = const DemoSpacing(),
      radius = const DemoRadius(),
      typography = const DemoTypography();

  final DemoColors colors;
  final DemoSpacing spacing;
  final DemoRadius radius;
  final DemoTypography typography;
}

class DemoColors {
  DemoColors(this._scheme);

  final ColorScheme _scheme;

  Color get brandPrimary => _scheme.primary;
  Color get brandSecondary => _scheme.tertiary;
  Color get success => Colors.green.shade600;
  Color get warning => Colors.orange.shade700;
  Color get surface => _scheme.surface;
  Color get surfaceMuted => _scheme.surfaceContainerHighest;
  Color get borderDefault => _scheme.outlineVariant;
  Color get textPrimary => _scheme.onSurface;
  Color get textSecondary => _scheme.onSurfaceVariant;
  Color get textInverse => _scheme.onPrimary;
}

class DemoSpacing {
  const DemoSpacing();

  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xxl = 24;
  final double page = 16;
}

class DemoRadius {
  const DemoRadius();

  final double card = 8;
  final double lg = 12;
  final double pill = 999;
}

class DemoTypography {
  const DemoTypography();

  DemoTextStyle get caption => const DemoTextStyle(fontSize: 12);
}

class DemoTextStyle {
  const DemoTextStyle({required this.fontSize});

  final double fontSize;

  TextStyle toTextStyle(Color color) {
    return TextStyle(color: color, fontSize: fontSize);
  }
}

enum Host4TextRole { body, heading }

enum Host4TextColorRole { primary, secondary }

class Host4Text extends StatelessWidget {
  const Host4Text(
    this.text, {
    this.role = Host4TextRole.body,
    this.colorRole = Host4TextColorRole.primary,
    super.key,
  });

  final String text;
  final Host4TextRole role;
  final Host4TextColorRole colorRole;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = switch (role) {
      Host4TextRole.heading => Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      Host4TextRole.body => Theme.of(context).textTheme.bodyMedium,
    };
    final color = switch (colorRole) {
      Host4TextColorRole.primary => colors.onSurface,
      Host4TextColorRole.secondary => colors.onSurfaceVariant,
    };

    return Text(text, style: style?.copyWith(color: color));
  }
}
