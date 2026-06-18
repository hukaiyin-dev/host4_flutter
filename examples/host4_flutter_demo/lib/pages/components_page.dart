import 'package:flutter/material.dart';
import 'package:host4_flutter_system_status/host4_flutter_system_status.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../widgets/list_icon.dart';

class ComponentsPage extends StatelessWidget {
  const ComponentsPage({super.key});

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
      children: _withComponentCellGaps([
        Host4ListCell(
          title: 'Host4Text',
          subtitle: 'Typography roles',
          leading: ListIcon(
            icon: Icons.text_fields_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4Text',
                child: _TypographyDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4Button',
          subtitle: 'Variants, states and icon combinations',
          leading: ListIcon(
            icon: Icons.smart_button_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _ComponentDemoScaffold(
                title: 'Host4Button',
                subtitle: 'Variants, states and icon combinations',
                child: const ButtonsPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4SegmentedFilter',
          subtitle: 'Tab-style selector',
          leading: ListIcon(
            icon: Icons.tune_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4SegmentedFilter',
                child: _SegmentedFilterDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4TopBar',
          subtitle: 'Page header — title, breadcrumb, icons and search',
          leading: ListIcon(
            icon: Icons.web_asset_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _TopBarDemoScaffold(),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4Toolbar',
          subtitle: 'Search and filter bar',
          leading: ListIcon(
            icon: Icons.search_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4Toolbar',
                child: _ToolbarDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4ProgressBar',
          subtitle: 'Linear progress',
          leading: ListIcon(
            icon: Icons.linear_scale_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4ProgressBar',
                child: _ProgressBarDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4Tag',
          subtitle: 'Label chip with states',
          leading: ListIcon(
            icon: Icons.label_outline_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4Tag',
                child: _TagDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4Banner',
          subtitle: 'Info, success, warning and error messages',
          leading: ListIcon(
            icon: Icons.campaign_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4Banner',
                child: _BannerDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4InfoChip',
          subtitle: 'Key-value label',
          leading: ListIcon(
            icon: Icons.info_outline_rounded,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4InfoChip',
                child: _InfoChipDemoPage(),
              ),
            ),
          ),
        ),
        Host4ListCell(
          title: 'Host4EmptyState',
          subtitle: 'Icon, title and action',
          leading: ListIcon(
            icon: Icons.inbox_outlined,
            color: theme.colors.brandPrimary,
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const _ComponentDemoScaffold(
                title: 'Host4EmptyState',
                child: _EmptyStateDemoPage(),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

List<Widget> _withComponentCellGaps(List<Widget> children) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 6),
      children[index],
    ],
  ];
}

// ─── Typography Demo ─────────────────────────────────────────────────────────

class _TypographyDemoPage extends StatelessWidget {
  const _TypographyDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(
          title: 'Typography Roles',
          subtitle: 'Size / line height / weight roles',
        ),
        SizedBox(height: theme.spacing.md),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final spec in _typographySpecs) ...[
                _TypographySpecRow(spec: spec),
                if (spec != _typographySpecs.last)
                  SizedBox(height: theme.spacing.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TypographySpec {
  const _TypographySpec({
    required this.name,
    required this.role,
    required this.size,
    required this.lineHeight,
    required this.weight,
    required this.usage,
  });

  final String name;
  final Host4TextRole role;
  final String size;
  final String lineHeight;
  final String weight;
  final String usage;
}

const List<_TypographySpec> _typographySpecs = [
  _TypographySpec(
    name: 'display',
    role: Host4TextRole.display,
    size: '32sp',
    lineHeight: '36dp',
    weight: 'Bold',
    usage: '特殊标题 D1',
  ),
  _TypographySpec(
    name: 'title',
    role: Host4TextRole.title,
    size: '24sp',
    lineHeight: '36dp',
    weight: 'Medium',
    usage: '标题 H1',
  ),
  _TypographySpec(
    name: 'title regular',
    role: Host4TextRole.titleRegular,
    size: '24sp',
    lineHeight: '36dp',
    weight: 'Regular',
    usage: '标题 H1 常规字重',
  ),
  _TypographySpec(
    name: 'heading',
    role: Host4TextRole.heading,
    size: '18sp',
    lineHeight: '24dp',
    weight: 'Medium',
    usage: '正文 B2 / 列表标题',
  ),
  _TypographySpec(
    name: 'body medium',
    role: Host4TextRole.bodyMedium,
    size: '16sp',
    lineHeight: '22dp',
    weight: 'Medium',
    usage: 'Body B1',
  ),
  _TypographySpec(
    name: 'body regular',
    role: Host4TextRole.bodyRegular,
    size: '16sp',
    lineHeight: '22dp',
    weight: 'Regular',
    usage: 'Body B2',
  ),
  _TypographySpec(
    name: 'label medium',
    role: Host4TextRole.labelMedium,
    size: '14sp',
    lineHeight: '22dp',
    weight: 'Medium',
    usage: 'Label L1',
  ),
  _TypographySpec(
    name: 'label regular',
    role: Host4TextRole.labelRegular,
    size: '14sp',
    lineHeight: '22dp',
    weight: 'Regular',
    usage: 'Label L2',
  ),
  _TypographySpec(
    name: 'caption',
    role: Host4TextRole.caption,
    size: '12sp',
    lineHeight: '20dp',
    weight: 'Regular',
    usage: 'Caption C2',
  ),
];

class _TypographySpecRow extends StatelessWidget {
  const _TypographySpecRow({required this.spec});

  final _TypographySpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Host4Text(
          spec.name,
          role: Host4TextRole.caption,
          colorRole: Host4TextColorRole.secondary,
        ),
        SizedBox(height: theme.spacing.xs),
        Host4Text('欢迎使用 Pantas', role: spec.role),
        SizedBox(height: theme.spacing.xs),
        Host4Text(
          '${spec.size} / ${spec.lineHeight} / ${spec.weight} · ${spec.usage}',
          role: Host4TextRole.caption,
          colorRole: Host4TextColorRole.secondary,
        ),
      ],
    );
  }
}

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

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
      children: [
        Host4SectionHeader(
          title: 'Button Variants',
          subtitle: 'Variants, sizes, content and states',
        ),
        SizedBox(height: theme.spacing.md),
        for (var index = 0; index < _buttonDemoGroups.length; index++) ...[
          _ButtonDemoGroupView(column: _buttonDemoGroups[index]),
          if (index != _buttonDemoGroups.length - 1)
            SizedBox(height: theme.spacing.md),
        ],
      ],
    );
  }
}

enum _ButtonPreviewState { defaultState, hover, pressed, focused, selected }

class _ButtonDemoGroup {
  const _ButtonDemoGroup({required this.buttons});

  final List<_ButtonDemoSpec> buttons;
}

class _ButtonDemoSpec {
  const _ButtonDemoSpec({
    required this.variant,
    required this.size,
    required this.content,
    required this.state,
    this.icon,
  });

  final Host4ButtonVariant variant;
  final Host4ButtonSize size;
  final Host4ButtonContent content;
  final _ButtonPreviewState state;
  final String? icon;

  bool get showsLabel => content != Host4ButtonContent.iconOnly;
}

class _ButtonDemoMetrics {
  const _ButtonDemoMetrics({
    required this.width,
    required this.height,
    required this.iconSize,
  });

  final double width;
  final double height;
  final double iconSize;
}

const String _buttonDemoIcon = Host4IconAssets.hamburger;

const List<_ButtonDemoGroup> _buttonDemoGroups = [
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.selected,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.selected,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconRight,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.ghost,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.iconOnly,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.primary,
        size: Host4ButtonSize.xs,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverPrimary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.popoverSecondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.selected,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerSoft,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.dangerHigh,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.defaultState,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.hover,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.pressed,
        icon: _buttonDemoIcon,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.md,
        content: Host4ButtonContent.iconLeft,
        state: _ButtonPreviewState.focused,
        icon: _buttonDemoIcon,
      ),
    ],
  ),
  _ButtonDemoGroup(
    buttons: [
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.defaultState,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.hover,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.pressed,
      ),
      _ButtonDemoSpec(
        variant: Host4ButtonVariant.secondary,
        size: Host4ButtonSize.sm,
        content: Host4ButtonContent.textOnly,
        state: _ButtonPreviewState.focused,
      ),
    ],
  ),
];

class _ButtonDemoGroupView extends StatelessWidget {
  const _ButtonDemoGroupView({required this.column});

  final _ButtonDemoGroup column;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final first = column.buttons.first;

    return Host4Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Host4Text(_buttonGroupTitle(first), role: Host4TextRole.labelMedium),
          SizedBox(height: theme.spacing.xs),
          Host4Text(
            _buttonGroupSubtitle(first),
            role: Host4TextRole.caption,
            colorRole: Host4TextColorRole.secondary,
          ),
          SizedBox(height: theme.spacing.md),
          for (var index = 0; index < column.buttons.length; index++) ...[
            _ButtonDemoStateRow(spec: column.buttons[index]),
            if (index != column.buttons.length - 1)
              SizedBox(height: theme.spacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ButtonDemoStateRow extends StatelessWidget {
  const _ButtonDemoStateRow({required this.spec});

  final _ButtonDemoSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Host4Text(
            _stateLabel(spec.state),
            role: Host4TextRole.caption,
            colorRole: Host4TextColorRole.secondary,
          ),
        ),
        SizedBox(width: theme.spacing.sm),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _ButtonDemoPreview(spec: spec),
          ),
        ),
      ],
    );
  }
}

class _ButtonDemoPreview extends StatelessWidget {
  const _ButtonDemoPreview({required this.spec});

  final _ButtonDemoSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final buttonTokens = theme.components.button;
    final variantTokens = _variantTokens(buttonTokens, spec.variant);
    final stateTokens = _stateTokens(variantTokens, spec.state);
    final metrics = _metricsFor(spec);
    final ring = buttonTokens.focusedRing;
    final icon = spec.icon;

    Widget child;
    if (spec.content == Host4ButtonContent.iconOnly) {
      child = icon == null
          ? const SizedBox.shrink()
          : Host4SvgIcon(
              assetPath: icon,
              size: metrics.iconSize,
              color: stateTokens.foreground,
            );
    } else if (spec.content == Host4ButtonContent.iconLeft) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Host4SvgIcon(
              assetPath: icon,
              size: metrics.iconSize,
              color: stateTokens.foreground,
            ),
            SizedBox(width: buttonTokens.spacing.iconGap),
          ],
          Text(
            'Button',
            style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
          ),
        ],
      );
    } else if (spec.content == Host4ButtonContent.iconRight) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Button',
            style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
          ),
          if (icon != null) ...[
            SizedBox(width: buttonTokens.spacing.iconGap),
            Host4SvgIcon(
              assetPath: icon,
              size: metrics.iconSize,
              color: stateTokens.foreground,
            ),
          ],
        ],
      );
    } else {
      child = Text(
        'Button',
        style: buttonTokens.labelStyle.toTextStyle(stateTokens.foreground),
      );
    }

    if (spec.state == _ButtonPreviewState.selected &&
        spec.variant == Host4ButtonVariant.ghost &&
        spec.content != Host4ButtonContent.iconOnly) {
      final indicator = buttonTokens.selectedIndicator;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          SizedBox(height: indicator.gap),
          Container(
            width: indicator.width,
            height: indicator.height,
            decoration: BoxDecoration(
              color: indicator.color,
              borderRadius: BorderRadius.circular(indicator.height / 2),
            ),
          ),
        ],
      );
    }

    final button = Container(
      width: metrics.width,
      height: metrics.height,
      decoration: BoxDecoration(
        color: stateTokens.background,
        borderRadius: BorderRadius.circular(variantTokens.radius),
        border: _buttonPreviewBorder(stateTokens),
      ),
      alignment: Alignment.center,
      child: child,
    );

    Widget result = button;
    if (stateTokens.opacity < 1) {
      result = Opacity(opacity: stateTokens.opacity, child: result);
    }

    if (spec.state != _ButtonPreviewState.focused ||
        !variantTokens.focusRingVisible) {
      return result;
    }

    return Container(
      padding: EdgeInsets.all(ring.offsetWidth),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ring.radius > 0
              ? ring.radius
              : variantTokens.radius + ring.offsetWidth + ring.width,
        ),
        border: Border.all(color: ring.color, width: ring.width),
      ),
      child: result,
    );
  }
}

Border _buttonPreviewBorder(Host4ButtonStateTokens stateTokens) {
  if (stateTokens.bottomBorderWidth > 0) {
    return Border(
      bottom: BorderSide(
        color: stateTokens.border,
        width: stateTokens.bottomBorderWidth,
      ),
    );
  }
  return Border.all(color: stateTokens.border);
}

Host4ButtonVariantTokens _variantTokens(
  Host4ButtonComponentTokens buttonTokens,
  Host4ButtonVariant variant,
) {
  return switch (variant) {
    Host4ButtonVariant.ghost => buttonTokens.ghost,
    Host4ButtonVariant.primary => buttonTokens.primary,
    Host4ButtonVariant.secondary => buttonTokens.secondary,
    Host4ButtonVariant.popoverPrimary => buttonTokens.popoverPrimary,
    Host4ButtonVariant.popoverSecondary => buttonTokens.popoverSecondary,
    Host4ButtonVariant.tertiary => buttonTokens.tertiary,
    Host4ButtonVariant.dangerHigh => buttonTokens.dangerHigh,
    Host4ButtonVariant.dangerSoft => buttonTokens.dangerSoft,
  };
}

Host4ButtonStateTokens _stateTokens(
  Host4ButtonVariantTokens variantTokens,
  _ButtonPreviewState state,
) {
  return switch (state) {
    _ButtonPreviewState.defaultState => variantTokens.defaultState,
    _ButtonPreviewState.hover => variantTokens.hoverState,
    _ButtonPreviewState.pressed => variantTokens.pressedState,
    _ButtonPreviewState.focused => variantTokens.focusedState,
    _ButtonPreviewState.selected =>
      variantTokens.selectedState ?? variantTokens.defaultState,
  };
}

_ButtonDemoMetrics _metricsFor(_ButtonDemoSpec spec) {
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.textOnly) {
    if (spec.state == _ButtonPreviewState.selected) {
      return const _ButtonDemoMetrics(width: 71, height: 27, iconSize: 16);
    }
    return const _ButtonDemoMetrics(width: 70, height: 26, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.md &&
      spec.content == Host4ButtonContent.textOnly) {
    return const _ButtonDemoMetrics(width: 70, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      (spec.content == Host4ButtonContent.iconLeft ||
          spec.content == Host4ButtonContent.iconRight)) {
    return const _ButtonDemoMetrics(width: 94, height: 32, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.iconOnly) {
    return const _ButtonDemoMetrics(width: 40, height: 32, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.ghost &&
      spec.size == Host4ButtonSize.xs &&
      spec.content == Host4ButtonContent.iconOnly) {
    return const _ButtonDemoMetrics(width: 24, height: 24, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.primary &&
      spec.size == Host4ButtonSize.sm) {
    return const _ButtonDemoMetrics(width: 94, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.primary &&
      spec.size == Host4ButtonSize.xs) {
    return const _ButtonDemoMetrics(width: 62, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.popoverPrimary) {
    return const _ButtonDemoMetrics(width: 78, height: 42, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.popoverSecondary) {
    return const _ButtonDemoMetrics(width: 78, height: 42, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.dangerSoft &&
      spec.content == Host4ButtonContent.iconLeft) {
    return const _ButtonDemoMetrics(width: 94, height: 40, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.dangerHigh) {
    return const _ButtonDemoMetrics(width: 94, height: 34, iconSize: 16);
  }
  if (spec.variant == Host4ButtonVariant.secondary &&
      spec.size == Host4ButtonSize.md &&
      spec.content == Host4ButtonContent.iconLeft) {
    return const _ButtonDemoMetrics(width: 94, height: 40, iconSize: 20);
  }
  if (spec.variant == Host4ButtonVariant.secondary &&
      spec.size == Host4ButtonSize.sm &&
      spec.content == Host4ButtonContent.textOnly) {
    return const _ButtonDemoMetrics(width: 62, height: 34, iconSize: 16);
  }

  return const _ButtonDemoMetrics(width: 94, height: 34, iconSize: 16);
}

String _buttonGroupTitle(_ButtonDemoSpec spec) {
  return '${_variantLabel(spec.variant)} / ${_sizeLabel(spec.size)}';
}

String _buttonGroupSubtitle(_ButtonDemoSpec spec) {
  return '${_contentLabel(spec.content)} · ${spec.showsLabel ? 'label' : 'icon only'}';
}

String _variantLabel(Host4ButtonVariant variant) {
  return switch (variant) {
    Host4ButtonVariant.ghost => 'ghost',
    Host4ButtonVariant.primary => 'primary',
    Host4ButtonVariant.secondary => 'secondary',
    Host4ButtonVariant.popoverPrimary => 'popover primary',
    Host4ButtonVariant.popoverSecondary => 'popover secondary',
    Host4ButtonVariant.dangerHigh => 'danger high',
    Host4ButtonVariant.dangerSoft => 'danger soft',
    Host4ButtonVariant.tertiary => 'tertiary',
  };
}

String _sizeLabel(Host4ButtonSize size) {
  return switch (size) {
    Host4ButtonSize.xs => 'xs',
    Host4ButtonSize.sm => 'sm',
    Host4ButtonSize.md => 'md',
  };
}

String _contentLabel(Host4ButtonContent content) {
  return switch (content) {
    Host4ButtonContent.textOnly => 'text only',
    Host4ButtonContent.iconLeft => 'icon left',
    Host4ButtonContent.iconRight => 'icon right',
    Host4ButtonContent.iconOnly => 'icon only',
  };
}

String _stateLabel(_ButtonPreviewState state) {
  return switch (state) {
    _ButtonPreviewState.defaultState => 'default',
    _ButtonPreviewState.hover => 'hover',
    _ButtonPreviewState.pressed => 'pressed',
    _ButtonPreviewState.focused => 'focused',
    _ButtonPreviewState.selected => 'selected',
  };
}

// ─── Tag Demo ────────────────────────────────────────────────────────────────

class _TagDemoPage extends StatelessWidget {
  const _TagDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(title: 'Variants', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: [
            Host4Tag(label: 'Normal'),
            Host4Tag(label: 'Selected', variant: Host4TagVariant.selected),
            Host4Tag(label: 'Disabled', variant: Host4TagVariant.disabled),
          ],
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'With Icon', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: [
            // TODO: pass SVG asset paths once Figma icons are exported
            const Host4Tag(label: 'Normal'),
            const Host4Tag(
              label: 'Selected',
              variant: Host4TagVariant.selected,
            ),
            const Host4Tag(
              label: 'Disabled',
              variant: Host4TagVariant.disabled,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Tappable', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: [Host4Tag(label: 'Tap me', onTap: () {})],
        ),
      ],
    );
  }
}

// ─── Empty State Demo ─────────────────────────────────────────────────────────

class _EmptyStateDemoPage extends StatelessWidget {
  const _EmptyStateDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(
          title: 'Full',
          subtitle: 'Icon + title + subtitle + action',
        ),
        SizedBox(height: theme.spacing.md),
        SizedBox(
          height: 280,
          child: Host4EmptyState(
            // TODO: icon: 'assets/icons/inbox.svg' once Figma icons are exported
            title: 'No items yet',
            subtitle: 'Add your first item to get started.',
            action: Host4Button(
              label: 'Add Item',
              variant: Host4ButtonVariant.primary,
              size: Host4ButtonSize.sm,
              onPressed: () {},
            ),
          ),
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Title Only', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        SizedBox(height: 180, child: Host4EmptyState(title: 'Nothing here')),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Icon + Title', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        SizedBox(
          height: 220,
          child: Host4EmptyState(
            // TODO: icon: 'assets/icons/search_off.svg' once Figma icons are exported
            title: 'No results found',
            subtitle: 'Try adjusting your search or filters.',
          ),
        ),
      ],
    );
  }
}

// ─── Banner Demo ──────────────────────────────────────────────────────────────

class _BannerDemoPage extends StatelessWidget {
  const _BannerDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(title: 'Info', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4Banner(
          // TODO: icon: 'assets/icons/info.svg' once Figma icons are exported
          title: 'Information',
          body: 'This is an informational message for the user.',
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Success', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4Banner(
          // TODO: icon: 'assets/icons/check_circle.svg' once Figma icons are exported
          title: 'Success',
          body: 'Your changes have been saved successfully.',
          variant: Host4BannerVariant.success,
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Warning', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4Banner(
          // TODO: icon: 'assets/icons/warning.svg' once Figma icons are exported
          title: 'Warning',
          body: 'Please review the highlighted fields before proceeding.',
          variant: Host4BannerVariant.warning,
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Error', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4Banner(
          // TODO: icon: 'assets/icons/error.svg' once Figma icons are exported
          title: 'Error',
          body: 'Something went wrong. Please try again.',
          variant: Host4BannerVariant.error,
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Title Only', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4Banner(title: 'No body text, no icon.'),
      ],
    );
  }
}

// ─── Progress Bar Demo ────────────────────────────────────────────────────────

class _ProgressBarDemoPage extends StatelessWidget {
  const _ProgressBarDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(title: 'Normal', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4ProgressBar(value: 0.65),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Success', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4ProgressBar(value: 1.0, variant: Host4ProgressBarVariant.success),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Warning', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4ProgressBar(value: 0.45, variant: Host4ProgressBarVariant.warning),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Error', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4ProgressBar(value: 0.2, variant: Host4ProgressBarVariant.error),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'Indeterminate', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4ProgressBar(value: null),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(
          title: 'Steps',
          subtitle: '0% / 25% / 50% / 75% / 100%',
        ),
        SizedBox(height: theme.spacing.md),
        for (final v in [0.0, 0.25, 0.5, 0.75, 1.0]) ...[
          Host4ProgressBar(value: v),
          SizedBox(height: theme.spacing.sm),
        ],
      ],
    );
  }
}

// ─── Segmented Filter Demo ────────────────────────────────────────────────────

class _SegmentedFilterDemoPage extends StatefulWidget {
  const _SegmentedFilterDemoPage();

  @override
  State<_SegmentedFilterDemoPage> createState() =>
      _SegmentedFilterDemoPageState();
}

class _SegmentedFilterDemoPageState extends State<_SegmentedFilterDemoPage> {
  int _selectedIndex = 0;
  int _selectedWithIconIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(title: 'Text Only', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4SegmentedFilter(
          items: const [
            Host4SegmentedFilterItem(label: 'All'),
            Host4SegmentedFilterItem(label: 'Active'),
            Host4SegmentedFilterItem(label: 'Inactive'),
          ],
          selectedIndex: _selectedIndex,
          onChanged: (i) => setState(() => _selectedIndex = i),
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'With Icons', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Host4SegmentedFilter(
          // TODO: add icon: 'assets/icons/xxx.svg' once Figma icons are exported
          items: const [
            Host4SegmentedFilterItem(label: 'List'),
            Host4SegmentedFilterItem(label: 'Grid'),
            Host4SegmentedFilterItem(label: 'Map'),
          ],
          selectedIndex: _selectedWithIconIndex,
          onChanged: (i) => setState(() => _selectedWithIconIndex = i),
        ),
      ],
    );
  }
}

// ─── Info Chip Demo ───────────────────────────────────────────────────────────

class _InfoChipDemoPage extends StatelessWidget {
  const _InfoChipDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.all(theme.spacing.page),
      children: [
        Host4SectionHeader(title: 'Label Only', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: const [
            Host4InfoChip(label: 'Online'),
            Host4InfoChip(label: 'v2.3.1'),
            Host4InfoChip(label: '42 players'),
          ],
        ),
        SizedBox(height: theme.spacing.section),
        Host4SectionHeader(title: 'With Icon', subtitle: ''),
        SizedBox(height: theme.spacing.md),
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          // TODO: add icon: 'assets/icons/xxx.svg' once Figma icons are exported
          children: const [
            Host4InfoChip(label: 'Online'),
            Host4InfoChip(label: 'v2.3.1'),
            Host4InfoChip(label: '42 players'),
            Host4InfoChip(label: 'Low latency'),
          ],
        ),
      ],
    );
  }
}

// ─── Toolbar Demo ─────────────────────────────────────────────────────────────

class _ToolbarDemoPage extends StatelessWidget {
  const _ToolbarDemoPage();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Host4Toolbar(
          children: [
            Host4SearchBar(hintText: 'Search...'),
            Host4Button(
              label: 'Filter',
              variant: Host4ButtonVariant.ghost,
              size: Host4ButtonSize.sm,
              onPressed: () {},
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(theme.spacing.page),
            children: [
              Host4SectionHeader(
                title: 'Toolbar',
                subtitle: 'Pinned at top — search bar + icon button',
              ),
              SizedBox(height: theme.spacing.md),
              for (var i = 1; i <= 8; i++)
                Host4ListCell(
                  title: 'Item $i',
                  subtitle: 'Subtitle for item $i',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sub-page scaffold for component demo pages.
/// Uses a plain surface color (no background image) so components
/// are always shown against a neutral, predictable canvas.
class _ComponentDemoScaffold extends StatelessWidget {
  const _ComponentDemoScaffold({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: title,
              subtitle: subtitle,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── TopBar Demo ──────────────────────────────────────────────────────────────

/// 独立 Scaffold：TopBar 演示需要全宽渲染，不套 NavigationBar。
class _TopBarDemoScaffold extends StatelessWidget {
  const _TopBarDemoScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Scaffold(
      backgroundColor: theme.colors.pageBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: 'Host4TopBar',
              subtitle: 'Page header variants',
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
            ),
          ),
          const Expanded(child: _TopBarDemoPage()),
        ],
      ),
    );
  }
}

class _TopBarDemoPage extends StatefulWidget {
  const _TopBarDemoPage();

  @override
  State<_TopBarDemoPage> createState() => _TopBarDemoPageState();
}

class _TopBarDemoPageState extends State<_TopBarDemoPage> {
  // source 由 widget 树共享，所有变体共用同一个实例
  final _statusSource = Host4DefaultSystemStatusSource();

  @override
  void dispose() {
    _statusSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ListView(
      padding: EdgeInsets.only(bottom: theme.spacing.page),
      children: [
        // 1. 仅标题 + 系统状态
        _TopBarVariantSection(
          label: '仅标题',
          child: Host4TopBar(
            safeAreaTop: 0,
            title: '游戏列表',
            status: Host4SystemStatus(source: _statusSource),
          ),
        ),

        // 2. 标题 + 搜索（点击图标自动展开）
        _TopBarVariantSection(
          label: '标题 + 搜索图标',
          child: Host4TopBar(
            safeAreaTop: 0,
            title: '主题商店',
            searchPlaceholder: '搜索主题...',
            status: Host4SystemStatus(source: _statusSource),
          ),
        ),

        // 3. 面包屑 + 系统状态
        _TopBarVariantSection(
          label: '面包屑（无操作按钮）',
          child: Host4TopBar(
            safeAreaTop: 0,
            parent: '游戏',
            title: '游戏列表',
            status: Host4SystemStatus(source: _statusSource),
          ),
        ),

        // 4. 面包屑 + 搜索（点击图标自动展开）
        _TopBarVariantSection(
          label: '面包屑 + 搜索图标',
          child: Host4TopBar(
            safeAreaTop: 0,
            parent: '设置',
            title: '控制器设置',
            searchPlaceholder: '搜索设置项...',
            status: Host4SystemStatus(source: _statusSource),
          ),
        ),

        // 5. 无标题，多个图标按钮靠左（leading）+ 系统状态
        _TopBarVariantSection(
          label: '无标题 · 多图标按钮（靠左）',
          child: Host4TopBar(
            safeAreaTop: 0,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TopBarIconButton(icon: Icons.notifications_outlined, onTap: () {}),
                const SizedBox(width: 4),
                _TopBarIconButton(icon: Icons.settings_outlined, onTap: () {}),
                const SizedBox(width: 4),
                _TopBarIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
              ],
            ),
            status: Host4SystemStatus(source: _statusSource),
          ),
        ),
      ],
    );
  }
}

/// 带标签的演示容器：上方显示变体名称，下方全宽渲染 TopBar。
class _TopBarVariantSection extends StatelessWidget {
  const _TopBarVariantSection({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            theme.spacing.page,
            theme.spacing.section,
            theme.spacing.page,
            theme.spacing.sm,
          ),
          child: Host4Text(
            label,
            role: Host4TextRole.labelMedium,
            colorRole: Host4TextColorRole.secondary,
          ),
        ),
        // TopBar 全宽，带阴影便于和背景区分
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: theme.colors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

/// TopBar 右侧图标按钮，点击区域 40×40。
class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = context.host4Theme.components.topBar.title;

    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(child: Icon(icon, size: 22, color: color)),
      ),
    );
  }
}
