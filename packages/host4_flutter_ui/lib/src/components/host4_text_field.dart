import 'package:flutter/material.dart';

import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

enum Host4TextFieldState { normal, error, success }

class Host4TextField extends StatelessWidget {
  const Host4TextField({
    required this.hintText,
    super.key,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.state = Host4TextFieldState.normal,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final Host4TextFieldState state;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.textField;
    final baseState = _baseState(tokens);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: tokens.minHeight),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        enabled: enabled,
        readOnly: readOnly,
        cursorColor: baseState.border,
        style: tokens.textStyle.toTextStyle(baseState.text),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: tokens.placeholderStyle.toTextStyle(baseState.placeholder),
          filled: true,
          fillColor: baseState.background,
          prefixIcon: prefixIcon == null
              ? null
              : Icon(
                  prefixIcon,
                  color: baseState.icon,
                  size: tokens.prefixIconSize,
                ),
          suffixIcon: suffix == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(right: tokens.suffixGap),
                  child: suffix,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: tokens.paddingHorizontal,
            vertical: tokens.paddingVertical,
          ),
          enabledBorder: _border(tokens, baseState.border),
          focusedBorder: _border(tokens, _focusedBorder(tokens)),
          disabledBorder: _border(tokens, tokens.disabledState.border),
          border: _border(tokens, baseState.border),
        ),
      ),
    );
  }

  Host4TextFieldStateTokens _baseState(Host4TextFieldComponentTokens tokens) {
    if (!enabled) return tokens.disabledState;
    if (readOnly) return tokens.readOnlyState;
    return switch (state) {
      Host4TextFieldState.error => tokens.errorState,
      Host4TextFieldState.success => tokens.successState,
      Host4TextFieldState.normal => tokens.defaultState,
    };
  }

  Color _focusedBorder(Host4TextFieldComponentTokens tokens) {
    if (!enabled) return tokens.disabledState.border;
    if (readOnly) return tokens.readOnlyState.border;
    return switch (state) {
      Host4TextFieldState.error => tokens.errorState.border,
      Host4TextFieldState.success => tokens.successState.border,
      Host4TextFieldState.normal => tokens.focusedState.border,
    };
  }

  OutlineInputBorder _border(
    Host4TextFieldComponentTokens tokens,
    Color color,
  ) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radius),
      borderSide: BorderSide(color: color),
    );
  }
}
