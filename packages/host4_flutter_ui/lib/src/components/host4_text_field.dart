import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

class Host4TextField extends StatelessWidget {
  const Host4TextField({
    required this.hintText,
    super.key,
    this.controller,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
  });

  final String hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.textField;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      cursorColor: tokens.focusBorder,
      style: theme.typography.body.toTextStyle(tokens.text),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.typography.body.toTextStyle(tokens.placeholder),
        filled: true,
        fillColor: tokens.background,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: tokens.icon, size: 20),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: EdgeInsets.only(right: theme.spacing.sm),
                child: suffix,
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(
          horizontal: theme.spacing.inputHorizontal,
          vertical: theme.spacing.inputVertical,
        ),
        enabledBorder: _border(theme, tokens.border),
        focusedBorder: _border(theme, tokens.focusBorder),
        border: _border(theme, tokens.border),
      ),
    );
  }

  OutlineInputBorder _border(Host4RuntimeTheme theme, Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(theme.radius.input),
      borderSide: BorderSide(color: color),
    );
  }
}
