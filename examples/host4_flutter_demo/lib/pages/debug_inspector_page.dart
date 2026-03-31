import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../widgets/color_chip.dart';
import '../widgets/debug_row.dart';

class DebugInspectorPage extends StatelessWidget {
  const DebugInspectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: const [_DebugPanel()],
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final manager = context.host4ThemeManager;

    final entry = manager.catalog.firstWhere(
      (e) => e.id == manager.currentThemeId,
      orElse: () => manager.catalog.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Host4SectionHeader(
          title: 'Debug Info',
          subtitle: 'Runtime state · tap values to copy',
        ),
        SizedBox(height: theme.spacing.md),

        // ── Theme state ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Theme State', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              DebugRow(
                label: 'id  (manifest.json)',
                value: theme.meta.id,
                theme: theme,
              ),
              DebugRow(label: 'name', value: theme.meta.name, theme: theme),
              DebugRow(
                label: 'schema',
                value: theme.meta.schema,
                theme: theme,
              ),
              DebugRow(label: 'mode', value: theme.meta.mode, theme: theme),
              DebugRow(
                label: 'defaultMode',
                value: theme.meta.defaultMode,
                theme: theme,
              ),
              DebugRow(
                label: 'supportedModes',
                value: theme.meta.supportedModes.join(', '),
                theme: theme,
              ),
              DebugRow(
                label: 'tokens file',
                value: entry.tokensAssetPath,
                theme: theme,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),

        // ── Image paths ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Image Paths', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              DebugRow(
                label: 'pageBackground',
                value: theme.images.pageBackground,
                theme: theme,
              ),
              DebugRow(
                label: 'heroBanner',
                value: theme.images.heroBanner,
                theme: theme,
              ),
              DebugRow(
                label: 'spotIllustration',
                value: theme.images.spotIllustration,
                theme: theme,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),

        // ── All color tokens ──
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text('Color Tokens', role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.md),
              Wrap(
                spacing: theme.spacing.sm,
                runSpacing: theme.spacing.sm,
                children: [
                  ColorChip(
                    label: 'brandPrimary',
                    color: theme.colors.brandPrimary,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'brandSecondary',
                    color: theme.colors.brandSecondary,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'brandAccent',
                    color: theme.colors.brandAccent,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'pageBackground',
                    color: theme.colors.pageBackground,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'surface',
                    color: theme.colors.surface,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'surfaceMuted',
                    color: theme.colors.surfaceMuted,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'surfaceElevated',
                    color: theme.colors.surfaceElevated,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'textPrimary',
                    color: theme.colors.textPrimary,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'textSecondary',
                    color: theme.colors.textSecondary,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'textInverse',
                    color: theme.colors.textInverse,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'borderDefault',
                    color: theme.colors.borderDefault,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'borderStrong',
                    color: theme.colors.borderStrong,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'focus',
                    color: theme.colors.focus,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'success',
                    color: theme.colors.success,
                    theme: theme,
                  ),
                  ColorChip(
                    label: 'warning',
                    color: theme.colors.warning,
                    theme: theme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
