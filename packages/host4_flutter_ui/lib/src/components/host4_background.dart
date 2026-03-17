import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4Background extends StatelessWidget {
  const Host4Background({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colors.pageBackground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BackgroundImage(
            imagePath: theme.images.pageBackground,
            tint: theme.colors.brandPrimary.withValues(alpha: 0.08),
            fallback: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colors.pageBackground,
                theme.colors.surfaceElevated,
              ],
            ),
          ),
          _BackgroundImage(
            imagePath: theme.images.pageOverlay,
            tint: theme.colors.brandAccent.withValues(alpha: 0.06),
            fallback: RadialGradient(
              center: const Alignment(0.8, -0.9),
              radius: 1.2,
              colors: [
                theme.colors.brandAccent.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({
    required this.imagePath,
    required this.tint,
    required this.fallback,
  });

  final String imagePath;
  final Color tint;
  final Gradient fallback;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: fallback),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        color: tint,
        colorBlendMode: BlendMode.srcATop,
        errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
      ),
    );
  }
}
