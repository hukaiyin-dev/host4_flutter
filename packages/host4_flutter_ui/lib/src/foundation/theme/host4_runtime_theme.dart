import 'package:flutter/material.dart';

@immutable
class Host4RuntimeTheme {
  const Host4RuntimeTheme({
    required this.meta,
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.sizes,
    required this.radius,
    required this.blur,
    required this.images,
    required this.components,
  });

  final Host4ThemeMeta meta;
  final Host4ThemeColors colors;
  final Host4ThemeTypography typography;
  final Host4ThemeSpacing spacing;
  final Host4ThemeSizes sizes;
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
    required this.interactivePressed,
    required this.interactiveDisabled,
    required this.interactiveSelected,
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
  final Color interactivePressed;
  final Color interactiveDisabled;
  final Color interactiveSelected;
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
  });

  final double sm;
  final double md;
  final double lg;
  final double pill;
  final double button;
  final double card;
  final double input;
}

@immutable
class Host4ThemeSizes {
  const Host4ThemeSizes({required this.iconMd, required this.iconLg});

  final double iconMd;
  final double iconLg;
}

@immutable
class Host4ThemeBlur {
  const Host4ThemeBlur({required this.card});

  final double card;
}

@immutable
class Host4ThemeImages {
  const Host4ThemeImages({
    required this.pageBackground,
    required this.heroBanner,
    required this.spotIllustration,
    required this.tabItems,
  });

  final String pageBackground;
  final String heroBanner;
  final String spotIllustration;

  /// Tab icon image pairs, ordered by index (tab0, tab1, …).
  /// Length equals the number of consecutive tab slots defined in the token.
  final List<Host4TabItemImages> tabItems;
}

@immutable
class Host4TabItemImages {
  const Host4TabItemImages({
    required this.normal,
    required this.selected,
    this.lightFallbackNormal,
    this.lightFallbackSelected,
  });

  final String normal;
  final String selected;

  /// Light-mode image path used as fallback when [normal] fails to load.
  /// Only set for non-light modes.
  final String? lightFallbackNormal;

  /// Light-mode image path used as fallback when [selected] fails to load.
  /// Only set for non-light modes.
  final String? lightFallbackSelected;
}

@immutable
class Host4ThemeComponents {
  const Host4ThemeComponents({
    required this.pageShell,
    required this.button,
    required this.card,
    required this.navigationBar,
    required this.searchBar,
    required this.sectionHeader,
    required this.textField,
    required this.listCell,
    required this.tabBar,
  });

  final Host4PageShellComponentTokens pageShell;
  final Host4ButtonComponentTokens button;
  final Host4CardComponentTokens card;
  final Host4NavigationBarComponentTokens navigationBar;
  final Host4SearchBarComponentTokens searchBar;
  final Host4SectionHeaderComponentTokens sectionHeader;
  final Host4TextFieldComponentTokens textField;
  final Host4ListCellComponentTokens listCell;
  final Host4TabBarComponentTokens tabBar;
}

@immutable
class Host4PageShellComponentTokens {
  const Host4PageShellComponentTokens({
    required this.pageColor,
    required this.image,
    required this.accentGlowColor,
    required this.accentGlowOpacity,
  });

  final Color pageColor;
  final String image;
  final Color accentGlowColor;
  final double accentGlowOpacity;
}

@immutable
class Host4ButtonComponentTokens {
  const Host4ButtonComponentTokens({
    required this.focusedRing,
    required this.spacing,
    required this.labelStyle,
    required this.minHeight,
    required this.leadingIconSize,
    required this.topIconSize,
    required this.iconOnlySize,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.outline,
    required this.ghost,
    required this.danger,
    required this.dangerSoft,
    required this.loading,
  });

  final Host4ButtonFocusedRingTokens focusedRing;
  final Host4ButtonSpacingTokens spacing;
  final Host4TextToken labelStyle;
  final double minHeight;
  final double leadingIconSize;
  final double topIconSize;
  final double iconOnlySize;
  final Host4ButtonVariantTokens primary;
  final Host4ButtonVariantTokens secondary;
  final Host4ButtonVariantTokens tertiary;
  final Host4ButtonVariantTokens outline;
  final Host4ButtonVariantTokens ghost;
  final Host4ButtonVariantTokens danger;
  final Host4ButtonVariantTokens dangerSoft;
  final Host4ButtonLoadingTokens loading;
}

@immutable
class Host4ButtonFocusedRingTokens {
  const Host4ButtonFocusedRingTokens({
    required this.color,
    required this.width,
    required this.offsetWidth,
  });

  final Color color;
  final double width;
  final double offsetWidth;
}

@immutable
class Host4ButtonLoadingTokens {
  const Host4ButtonLoadingTokens({
    required this.spinnerSize,
    required this.spinnerGap,
    required this.opacity,
  });

  final double spinnerSize;
  final double spinnerGap;
  final double opacity;
}

@immutable
class Host4ButtonSpacingTokens {
  const Host4ButtonSpacingTokens({
    required this.horizontal,
    required this.vertical,
    required this.iconOnlyHorizontal,
    required this.iconOnlyVertical,
    required this.iconGap,
    required this.stackGap,
    required this.smHorizontal,
    required this.smVertical,
    required this.mdHorizontal,
    required this.mdVertical,
    required this.lgHorizontal,
    required this.lgVertical,
  });

  final double horizontal;
  final double vertical;
  final double iconOnlyHorizontal;
  final double iconOnlyVertical;
  final double iconGap;
  final double stackGap;
  final double smHorizontal;
  final double smVertical;
  final double mdHorizontal;
  final double mdVertical;
  final double lgHorizontal;
  final double lgVertical;
}

@immutable
class Host4ButtonVariantTokens {
  const Host4ButtonVariantTokens({
    required this.radius,
    required this.defaultState,
    required this.hoverState,
    required this.pressedState,
    required this.disabledState,
    required this.focusedState,
  });

  final double radius;
  final Host4ButtonStateTokens defaultState;
  final Host4ButtonStateTokens hoverState;
  final Host4ButtonStateTokens pressedState;
  final Host4ButtonStateTokens disabledState;
  final Host4ButtonStateTokens focusedState;
}

@immutable
class Host4ButtonStateTokens {
  const Host4ButtonStateTokens({
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
    required this.padding,
    required this.radius,
    required this.background,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.shadowColor,
    required this.shadowOpacity,
    required this.shadowBlur,
    required this.shadowOffsetY,
  });

  final double padding;
  final double radius;
  final Color background;
  final Color border;
  final Color title;
  final Color subtitle;
  final Color shadowColor;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowOffsetY;
}

@immutable
class Host4NavigationBarComponentTokens {
  const Host4NavigationBarComponentTokens({
    required this.paddingHorizontal,
    required this.paddingTop,
    required this.paddingBottom,
    required this.leadingGap,
    required this.background,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final double paddingHorizontal;
  final double paddingTop;
  final double paddingBottom;
  final double leadingGap;
  final Color background;
  final Host4TextToken titleStyle;
  final Host4TextToken subtitleStyle;
  final Color title;
  final Color subtitle;
  final Color icon;
}

@immutable
class Host4SearchBarComponentTokens {
  const Host4SearchBarComponentTokens({
    required this.shortcutHorizontal,
    required this.shortcutVertical,
    required this.shortcutBackground,
    required this.shortcutRadius,
    required this.shortcutStyle,
    required this.shortcutTextColor,
  });

  final double shortcutHorizontal;
  final double shortcutVertical;
  final Color shortcutBackground;
  final double shortcutRadius;
  final Host4TextToken shortcutStyle;
  final Color shortcutTextColor;
}

@immutable
class Host4SectionHeaderComponentTokens {
  const Host4SectionHeaderComponentTokens({
    required this.titleStyle,
    required this.titleColor,
    required this.subtitleGap,
    required this.actionGap,
    required this.subtitleStyle,
    required this.subtitleColor,
  });

  final Host4TextToken titleStyle;
  final Color titleColor;
  final double subtitleGap;
  final double actionGap;
  final Host4TextToken subtitleStyle;
  final Color subtitleColor;
}

@immutable
class Host4TextFieldComponentTokens {
  const Host4TextFieldComponentTokens({
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.radius,
    required this.minHeight,
    required this.prefixIconSize,
    required this.suffixGap,
    required this.textStyle,
    required this.placeholderStyle,
    required this.defaultState,
    required this.focusedState,
    required this.disabledState,
    required this.readOnlyState,
    required this.errorState,
    required this.successState,
  });

  final double paddingHorizontal;
  final double paddingVertical;
  final double radius;
  final double minHeight;
  final double prefixIconSize;
  final double suffixGap;
  final Host4TextToken textStyle;
  final Host4TextToken placeholderStyle;
  final Host4TextFieldStateTokens defaultState;
  final Host4TextFieldStateTokens focusedState;
  final Host4TextFieldStateTokens disabledState;
  final Host4TextFieldStateTokens readOnlyState;
  final Host4TextFieldStateTokens errorState;
  final Host4TextFieldStateTokens successState;
}

@immutable
class Host4TextFieldStateTokens {
  const Host4TextFieldStateTokens({
    required this.background,
    required this.border,
    required this.text,
    required this.placeholder,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color placeholder;
  final Color icon;
}

@immutable
class Host4ListCellComponentTokens {
  const Host4ListCellComponentTokens({
    required this.radius,
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.minHeight,
    required this.leadingGap,
    required this.subtitleGap,
    required this.trailingGap,
    required this.chevronGap,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.trailingStyle,
    required this.defaultState,
    required this.pressedState,
    required this.disabledState,
    required this.selectedState,
  });

  final double radius;
  final double paddingHorizontal;
  final double paddingVertical;
  final double minHeight;
  final double leadingGap;
  final double subtitleGap;
  final double trailingGap;
  final double chevronGap;
  final Host4TextToken titleStyle;
  final Host4TextToken subtitleStyle;
  final Host4TextToken trailingStyle;
  final Host4ListCellStateTokens defaultState;
  final Host4ListCellStateTokens pressedState;
  final Host4ListCellStateTokens disabledState;
  final Host4ListCellStateTokens selectedState;
}

@immutable
class Host4ListCellStateTokens {
  const Host4ListCellStateTokens({
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

@immutable
class Host4TabBarComponentTokens {
  const Host4TabBarComponentTokens({
    required this.background,
    required this.height,
    required this.iconSize,
    required this.featuredIconSize,
    required this.labelStyle,
    required this.labelGap,
    required this.bottomGap,
    required this.itemStates,
    required this.items,
  });

  final Color background;
  final double height;
  final double iconSize;
  final double featuredIconSize;
  final Host4TextToken labelStyle;
  final double labelGap;
  final double bottomGap;
  final Host4TabBarItemStateSet itemStates;
  final List<Host4TabItemImages> items;
}

@immutable
class Host4TabBarItemStateSet {
  const Host4TabBarItemStateSet({
    required this.defaultState,
    required this.pressedState,
    required this.disabledState,
    required this.selectedState,
  });

  final Host4TabBarItemStateTokens defaultState;
  final Host4TabBarItemStateTokens pressedState;
  final Host4TabBarItemStateTokens disabledState;
  final Host4TabBarItemStateTokens selectedState;
}

@immutable
class Host4TabBarItemStateTokens {
  const Host4TabBarItemStateTokens({
    required this.labelColor,
    required this.iconColor,
  });

  final Color labelColor;
  final Color iconColor;
}
