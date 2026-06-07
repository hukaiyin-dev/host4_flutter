import 'package:flutter/material.dart';

import '../foundation/host4_svg_icon.dart';
import '../foundation/theme/host4_runtime_theme.dart';
import '../foundation/theme/host4_theme_scope.dart';

class Host4ListCell extends StatefulWidget {
  const Host4ListCell({
    required this.title,
    required this.subtitle,
    super.key,
    this.leading,
    this.trailingText,
    this.trailingIconAsset,
    this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? trailingText;
  /// SVG asset path for the trailing chevron/icon (e.g. `'assets/icons/chevron_right.svg'`).
  /// Pass `null` to hide the trailing icon.
  final String? trailingIconAsset;
  final VoidCallback? onTap;
  final bool enabled;
  final bool selected;

  @override
  State<Host4ListCell> createState() => _Host4ListCellState();
}

class _Host4ListCellState extends State<Host4ListCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final tokens = theme.components.listCell;
    final stateTokens = _stateTokens(tokens);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radius),
        onTap: widget.enabled ? widget.onTap : null,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        child: Container(
          constraints: BoxConstraints(minHeight: tokens.minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.paddingHorizontal,
            vertical: tokens.paddingVertical,
          ),
          decoration: BoxDecoration(
            color: stateTokens.background,
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: tokens.leadingGap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: tokens.titleStyle.toTextStyle(stateTokens.title),
                    ),
                    SizedBox(height: tokens.subtitleGap),
                    Text(
                      widget.subtitle,
                      style: tokens.subtitleStyle.toTextStyle(
                        stateTokens.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailingText != null) ...[
                SizedBox(width: tokens.trailingGap),
                Text(
                  widget.trailingText!,
                  style: tokens.trailingStyle.toTextStyle(stateTokens.trailing),
                ),
              ],
              if (widget.trailingIconAsset != null) ...[
                SizedBox(width: tokens.chevronGap),
                Host4SvgIcon(
                  assetPath: widget.trailingIconAsset!,
                  size: 20,
                  color: stateTokens.trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Host4ListCellStateTokens _stateTokens(Host4ListCellComponentTokens tokens) {
    if (!widget.enabled) return tokens.disabledState;
    if (_pressed) return tokens.pressedState;
    if (widget.selected) return tokens.selectedState;
    return tokens.defaultState;
  }
}
