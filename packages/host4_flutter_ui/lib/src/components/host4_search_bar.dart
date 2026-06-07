import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text_field.dart';

class Host4SearchBar extends StatelessWidget {
  const Host4SearchBar({
    required this.hintText,
    super.key,
    this.controller,
    this.onChanged,
    this.searchIconAsset,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  /// SVG asset path for the leading search icon (e.g. `'assets/icons/search.svg'`).
  /// Pass `null` to omit the icon.
  final String? searchIconAsset;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.searchBar;

    return Host4TextField(
      controller: controller,
      onChanged: onChanged,
      hintText: hintText,
      prefixIcon: searchIconAsset,
      suffix: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.shortcutHorizontal,
          vertical: tokens.shortcutVertical,
        ),
        decoration: BoxDecoration(
          color: tokens.shortcutBackground,
          borderRadius: BorderRadius.circular(tokens.shortcutRadius),
        ),
        child: Text(
          '⌘K',
          style: tokens.shortcutStyle.toTextStyle(tokens.shortcutTextColor),
        ),
      ),
    );
  }
}
