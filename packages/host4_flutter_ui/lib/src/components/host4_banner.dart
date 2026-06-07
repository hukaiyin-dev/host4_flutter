import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

enum Host4BannerVariant { info, success, warning, error }

class Host4Banner extends StatelessWidget {
  const Host4Banner({
    required this.title,
    super.key,
    this.icon,
    this.body,
    this.variant = Host4BannerVariant.info,
    this.trailing,
  });

  final IconData? icon;
  final String title;
  final String? body;
  final Host4BannerVariant variant;
  final Widget? trailing;

  Host4BannerVariantTokens _variantTokens(Host4BannerComponentTokens tokens) =>
      switch (variant) {
        Host4BannerVariant.success => tokens.success,
        Host4BannerVariant.warning => tokens.warning,
        Host4BannerVariant.error => tokens.error,
        _ => tokens.info,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = context.host4Theme.components.banner;
    final colors = _variantTokens(tokens);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.paddingHorizontal,
          vertical: tokens.paddingVertical,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: tokens.iconSize, color: colors.icon),
              SizedBox(width: tokens.iconGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: tokens.titleStyle.toTextStyle(colors.foreground),
                  ),
                  if (body != null) ...[
                    SizedBox(height: tokens.titleBodyGap),
                    Text(
                      body!,
                      style: tokens.bodyStyle.toTextStyle(colors.foreground),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: tokens.iconGap),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
