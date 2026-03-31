import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';

class Host4Background extends StatelessWidget {
  const Host4Background({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.pageShell;

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.pageColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _BackgroundImage(
            imagePath: tokens.image,
            fallbackColor: tokens.pageColor,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.8, -0.9),
                radius: 1.2,
                colors: [
                  tokens.accentGlowColor.withValues(
                    alpha: tokens.accentGlowOpacity,
                  ),
                  Colors.transparent,
                ],
              ),
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
    required this.fallbackColor,
  });

  final String imagePath;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: fallbackColor),
      child: imagePath.isEmpty
          ? const SizedBox.expand()
          : Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.expand(),
            ),
    );
  }
}
