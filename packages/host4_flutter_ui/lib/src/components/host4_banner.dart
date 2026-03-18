import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4Banner extends StatelessWidget {
  const Host4Banner({
    required this.title,
    required this.subtitle,
    required this.badge,
    super.key,
    this.imagePath,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String? imagePath;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final colors = theme.components.banner;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radius.banner),
        boxShadow: [
          BoxShadow(
            color: theme.colors.brandPrimary.withValues(alpha: 0.14),
            blurRadius: theme.blur.banner,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 8.6,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.background),
              child: Image.asset(
                imagePath ?? theme.images.heroBanner,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colors.brandPrimary,
                        theme.colors.brandSecondary,
                        theme.colors.brandAccent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    colors.overlay,
                    colors.overlay.withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.card),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: theme.spacing.sm,
                            vertical: theme.spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.badgeBackground,
                            borderRadius: BorderRadius.circular(
                              theme.radius.pill,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: theme.typography.caption
                                .toTextStyle(colors.badgeForeground),
                          ),
                        ),
                        SizedBox(height: theme.spacing.md),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.title
                              .toTextStyle(colors.title),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.typography.body.toTextStyle(
                            colors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: theme.spacing.md),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
