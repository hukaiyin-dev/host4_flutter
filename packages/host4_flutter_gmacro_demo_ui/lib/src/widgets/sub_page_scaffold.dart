import 'package:flutter/material.dart';

class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final parentTheme = Theme.of(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: parentTheme.colorScheme.primary,
      brightness: Brightness.light,
    );
    final theme = parentTheme.copyWith(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: parentTheme.appBarTheme.copyWith(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          leading: canPop ? const BackButton() : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: trailing == null ? null : [trailing!],
        ),
        body: child,
      ),
    );
  }
}
