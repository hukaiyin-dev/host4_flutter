import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A themed SVG icon that applies a solid [color] via [ColorFilter].
///
/// Use this anywhere a component needs to render a single-color icon
/// from a Figma-exported SVG asset. The [assetPath] is a Flutter asset
/// path (e.g. `'assets/icons/arrow_right.svg'`).
///
/// Color is applied with [BlendMode.srcIn], which replaces the SVG's
/// original fill/stroke with [color] while preserving transparency.
class Host4SvgIcon extends StatelessWidget {
  const Host4SvgIcon({
    required this.assetPath,
    required this.size,
    required this.color,
    super.key,
  });

  final String assetPath;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
