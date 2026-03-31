import 'package:flutter/material.dart';

import '../foundation/theme/host4_theme_scope.dart';
import 'host4_text_field.dart';

class Host4SearchBar extends StatelessWidget {
  const Host4SearchBar({required this.hintText, super.key, this.controller});

  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.searchBar;

    return Host4TextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icons.search_rounded,
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
