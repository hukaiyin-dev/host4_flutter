import 'package:flutter/material.dart';

@immutable
class Host4RuntimeTheme {
  const Host4RuntimeTheme({
    required this.meta,
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.blur,
    required this.images,
    required this.components,
  });

  final Host4ThemeMeta meta;
  final Host4ThemeColors colors;
  final Host4ThemeTypography typography;
  final Host4ThemeSpacing spacing;
  final Host4ThemeRadius radius;
  final Host4ThemeBlur blur;
  final Host4ThemeImages images;
  final Host4ThemeComponents components;
}

@immutable
class Host4ThemeMeta {
  const Host4ThemeMeta({
    required this.id,
    required this.name,
    required this.schema,
    required this.mode,
    required this.defaultMode,
    required this.supportedModes,
    required this.brightness,
  });

  final String id;
  final String name;
  final String schema;
  final String mode;
  final String defaultMode;
  final List<String> supportedModes;
  final Brightness brightness;
}

@immutable
class Host4ThemeColors {
  const Host4ThemeColors({
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandAccent,
    required this.pageBackground,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textInverse,
    required this.borderDefault,
    required this.borderStrong,
    required this.focus,
    required this.success,
    required this.warning,
  });

  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandAccent;
  final Color pageBackground;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textInverse;
  final Color borderDefault;
  final Color borderStrong;
  final Color focus;
  final Color success;
  final Color warning;
}

@immutable
class Host4ThemeTypography {
  const Host4ThemeTypography({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.label,
    required this.caption,
  });

  final Host4TextToken display;
  final Host4TextToken title;
  final Host4TextToken heading;
  final Host4TextToken body;
  final Host4TextToken label;
  final Host4TextToken caption;
}

@immutable
class Host4TextToken {
  const Host4TextToken({
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
    this.letterSpacing = 0,
  });

  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;
  final double letterSpacing;

  TextStyle toTextStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      height: lineHeight / fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }
}

@immutable
class Host4ThemeSpacing {
  const Host4ThemeSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.page,
    required this.section,
    required this.card,
    required this.buttonHorizontal,
    required this.buttonVertical,
    required this.inputHorizontal,
    required this.inputVertical,
    required this.listGap,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double page;
  final double section;
  final double card;
  final double buttonHorizontal;
  final double buttonVertical;
  final double inputHorizontal;
  final double inputVertical;
  final double listGap;
}

@immutable
class Host4ThemeRadius {
  const Host4ThemeRadius({
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
    required this.button,
    required this.card,
    required this.input,
    required this.banner,
  });

  final double sm;
  final double md;
  final double lg;
  final double pill;
  final double button;
  final double card;
  final double input;
  final double banner;
}

@immutable
class Host4ThemeBlur {
  const Host4ThemeBlur({
    required this.card,
    required this.banner,
    required this.chrome,
  });

  final double card;
  final double banner;
  final double chrome;
}

@immutable
class Host4ThemeImages {
  const Host4ThemeImages({
    required this.pageBackground,
    required this.pageOverlay,
    required this.heroBanner,
    required this.promoBanner,
    required this.spotIllustration,
  });

  final String pageBackground;
  final String pageOverlay;
  final String heroBanner;
  final String promoBanner;
  final String spotIllustration;
}

@immutable
class Host4ThemeComponents {
  const Host4ThemeComponents({
    required this.button,
    required this.card,
    required this.navigationBar,
    required this.textField,
    required this.banner,
    required this.listCell,
  });

  final Host4ButtonComponentTokens button;
  final Host4CardComponentTokens card;
  final Host4NavigationBarComponentTokens navigationBar;
  final Host4TextFieldComponentTokens textField;
  final Host4BannerComponentTokens banner;
  final Host4ListCellComponentTokens listCell;
}

@immutable
class Host4ButtonComponentTokens {
  const Host4ButtonComponentTokens({
    required this.primary,
    required this.secondary,
    required this.ghost,
  });

  final Host4ButtonVariantTokens primary;
  final Host4ButtonVariantTokens secondary;
  final Host4ButtonVariantTokens ghost;
}

@immutable
class Host4ButtonVariantTokens {
  const Host4ButtonVariantTokens({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

@immutable
class Host4CardComponentTokens {
  const Host4CardComponentTokens({
    required this.background,
    required this.border,
    required this.title,
    required this.subtitle,
  });

  final Color background;
  final Color border;
  final Color title;
  final Color subtitle;
}

@immutable
class Host4NavigationBarComponentTokens {
  const Host4NavigationBarComponentTokens({
    required this.background,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final Color background;
  final Color title;
  final Color subtitle;
  final Color icon;
}

@immutable
class Host4TextFieldComponentTokens {
  const Host4TextFieldComponentTokens({
    required this.background,
    required this.border,
    required this.focusBorder,
    required this.text,
    required this.placeholder,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color focusBorder;
  final Color text;
  final Color placeholder;
  final Color icon;
}

@immutable
class Host4BannerComponentTokens {
  const Host4BannerComponentTokens({
    required this.background,
    required this.overlay,
    required this.title,
    required this.subtitle,
    required this.badgeBackground,
    required this.badgeForeground,
  });

  final Color background;
  final Color overlay;
  final Color title;
  final Color subtitle;
  final Color badgeBackground;
  final Color badgeForeground;
}

@immutable
class Host4ListCellComponentTokens {
  const Host4ListCellComponentTokens({
    required this.background,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.divider,
  });

  final Color background;
  final Color title;
  final Color subtitle;
  final Color trailing;
  final Color divider;
}
