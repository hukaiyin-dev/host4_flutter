import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../widgets/color_chip.dart';
import '../widgets/debug_row.dart';

class LocalThemeListPage extends StatelessWidget {
  const LocalThemeListPage({required this.catalog, super.key});

  final List<Host4ThemeCatalogEntry> catalog;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.colors.surface,
        title: Text(
          '本地主题',
          style: theme.typography.heading.toTextStyle(theme.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: theme.colors.textPrimary),
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(theme.spacing.page),
        itemCount: catalog.length,
        separatorBuilder: (context, i) => SizedBox(height: theme.spacing.sm),
        itemBuilder: (context, index) {
          final entry = catalog[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocalThemeDetailPage(entry: entry),
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(theme.spacing.card),
              decoration: BoxDecoration(
                color: theme.colors.surface,
                borderRadius: BorderRadius.circular(theme.radius.md),
                border: Border.all(color: theme.colors.borderDefault),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: theme.typography.body.toTextStyle(
                            theme.colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: theme.spacing.xs),
                        Text(
                          entry.tokensAssetPath,
                          style: theme.typography.caption.toTextStyle(
                            theme.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: theme.colors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LocalThemeDetailPage extends StatefulWidget {
  const LocalThemeDetailPage({required this.entry, super.key});

  final Host4ThemeCatalogEntry entry;

  @override
  State<LocalThemeDetailPage> createState() => _LocalThemeDetailPageState();
}

class _LocalThemeDetailPageState extends State<LocalThemeDetailPage> {
  String _mode = 'light';
  Host4RuntimeTheme? _preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    try {
      final t = await Host4ThemeLoader.loadFromAsset(
        rootBundle,
        widget.entry.tokensAssetPath,
        mode: _mode,
      );
      if (mounted) {
        setState(() {
          _preview = t;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalTheme = context.host4Theme;
    final manager = context.host4ThemeManager;
    final theme = _preview ?? globalTheme;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      appBar: AppBar(
        backgroundColor: theme.colors.surface,
        title: Text(
          widget.entry.name,
          style: theme.typography.heading.toTextStyle(theme.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: theme.colors.textPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.page,
                theme.spacing.page,
                theme.spacing.page,
                theme.spacing.page + theme.spacing.xxl,
              ),
              children: [
                if (_preview != null) ...[
                  _ModeToggle(
                    mode: _mode,
                    onChanged: (m) {
                      _mode = m;
                      _loadPreview();
                    },
                    theme: theme,
                  ),
                  SizedBox(height: theme.spacing.md),
                  _ThemeColorPreview(preview: _preview!, theme: theme),
                  SizedBox(height: theme.spacing.md),
                  _ThemeDebugSection(preview: _preview!, theme: theme),
                ],
              ],
            ),
      bottomNavigationBar: _loading || _preview == null
          ? null
          : SafeArea(
              top: false,
              child: ColoredBox(
                color: theme.colors.pageBackground,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.spacing.page,
                    theme.spacing.sm,
                    theme.spacing.page,
                    theme.spacing.page,
                  ),
                  child: _PreviewButton(
                    label: '使用此主题',
                    icon: Icons.check_circle_outline,
                    theme: theme,
                    expanded: true,
                    onPressed: () async {
                      await manager.applyTheme(widget.entry.id, mode: _mode);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
    required this.theme,
  });

  final String mode;
  final ValueChanged<String> onChanged;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['light', 'dark'].map((m) {
        final selected = mode == m;
        return Padding(
          padding: EdgeInsets.only(right: theme.spacing.sm),
          child: _PreviewButton(
            label: m == 'light' ? 'Light' : 'Dark',
            theme: theme,
            variant: selected
                ? Host4ButtonVariant.primary
                : Host4ButtonVariant.secondary,
            onPressed: () => onChanged(m),
          ),
        );
      }).toList(),
    );
  }
}

class _ThemeColorPreview extends StatelessWidget {
  const _ThemeColorPreview({required this.preview, required this.theme});

  final Host4RuntimeTheme preview;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    final pairs = [
      ('Brand Primary', preview.colors.brandPrimary),
      ('Brand Secondary', preview.colors.brandSecondary),
      ('Brand Accent', preview.colors.brandAccent),
      ('Page BG', preview.colors.pageBackground),
      ('Surface', preview.colors.surface),
      ('Muted', preview.colors.surfaceMuted),
      ('Text Primary', preview.colors.textPrimary),
      ('Text Secondary', preview.colors.textSecondary),
      ('Border', preview.colors.borderDefault),
      ('Success', preview.colors.success),
      ('Warning', preview.colors.warning),
    ];

    return Container(
      padding: EdgeInsets.all(theme.spacing.card),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '颜色预览',
            style: theme.typography.label.toTextStyle(
              theme.colors.textSecondary,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          Wrap(
            spacing: theme.spacing.sm,
            runSpacing: theme.spacing.sm,
            children: pairs
                .map((p) => ColorChip(label: p.$1, color: p.$2, theme: theme))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeDebugSection extends StatelessWidget {
  const _ThemeDebugSection({required this.preview, required this.theme});

  final Host4RuntimeTheme preview;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreviewCard(
          theme: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme State',
                style: t.typography.heading.toTextStyle(t.colors.textPrimary),
              ),
              SizedBox(height: t.spacing.md),
              DebugRow(label: 'id', value: preview.meta.id, theme: t),
              DebugRow(label: 'name', value: preview.meta.name, theme: t),
              DebugRow(label: 'schema', value: preview.meta.schema, theme: t),
              DebugRow(label: 'mode', value: preview.meta.mode, theme: t),
              DebugRow(
                label: 'supportedModes',
                value: preview.meta.supportedModes.join(', '),
                theme: t,
              ),
            ],
          ),
        ),
        SizedBox(height: t.spacing.md),
        _PreviewCard(
          theme: t,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image Paths',
                style: t.typography.heading.toTextStyle(t.colors.textPrimary),
              ),
              SizedBox(height: t.spacing.md),
              DebugRow(
                label: 'pageBackground',
                value: preview.images.pageBackground,
                theme: t,
              ),
              DebugRow(
                label: 'heroBanner',
                value: preview.images.heroBanner,
                theme: t,
              ),
              DebugRow(
                label: 'spotIllustration',
                value: preview.images.spotIllustration,
                theme: t,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.theme, required this.child});

  final Host4RuntimeTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.card),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.borderDefault),
      ),
      child: child,
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.label,
    required this.theme,
    required this.onPressed,
    this.icon,
    this.variant = Host4ButtonVariant.primary,
    this.expanded = false,
  });

  final String label;
  final Host4RuntimeTheme theme;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Host4ButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final buttonTokens = theme.components.button;
    final variantTokens = switch (variant) {
      Host4ButtonVariant.secondary => buttonTokens.secondary,
      Host4ButtonVariant.ghost => buttonTokens.ghost,
      _ => buttonTokens.primary,
    };
    final colors = variantTokens.defaultState;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(variantTokens.radius),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: buttonTokens.minHeight),
          child: Ink(
            width: expanded ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: buttonTokens.spacing.horizontal,
              vertical: buttonTokens.spacing.vertical,
            ),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(variantTokens.radius),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: colors.foreground),
                  SizedBox(width: theme.spacing.sm),
                ],
                Text(
                  label,
                  style: buttonTokens.labelStyle.toTextStyle(colors.foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
