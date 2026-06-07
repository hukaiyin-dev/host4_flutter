import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

enum Host4TextRole {
  display,
  title,
  titleRegular,
  heading,
  body,
  bodyMedium,
  bodyRegular,
  label,
  labelMedium,
  labelRegular,
  caption,
}

enum Host4TextColorRole { primary, secondary, inverse, accent }

class Host4Text extends StatelessWidget {
  const Host4Text(
    this.data, {
    super.key,
    this.role = Host4TextRole.body,
    this.colorRole = Host4TextColorRole.primary,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final Host4TextRole role;
  final Host4TextColorRole colorRole;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final token = switch (role) {
      Host4TextRole.display => theme.typography.display,
      Host4TextRole.title => theme.typography.title,
      Host4TextRole.titleRegular => theme.typography.titleRegular,
      Host4TextRole.heading => theme.typography.heading,
      Host4TextRole.body => theme.typography.body,
      Host4TextRole.bodyMedium => theme.typography.bodyMedium,
      Host4TextRole.bodyRegular => theme.typography.bodyRegular,
      Host4TextRole.label => theme.typography.label,
      Host4TextRole.labelMedium => theme.typography.labelMedium,
      Host4TextRole.labelRegular => theme.typography.labelRegular,
      Host4TextRole.caption => theme.typography.caption,
    };
    final color = switch (colorRole) {
      Host4TextColorRole.primary => theme.colors.textPrimary,
      Host4TextColorRole.secondary => theme.colors.textSecondary,
      Host4TextColorRole.inverse => theme.colors.textInverse,
      Host4TextColorRole.accent => theme.colors.brandAccent,
    };

    return Text(
      data,
      maxLines: maxLines,
      overflow: overflow,
      style: style ?? token.toTextStyle(color),
    );
  }
}
