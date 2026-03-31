import 'dart:io';

import 'package:flutter/material.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../theme_job.dart';
import '../../theme_job_poller.dart';

class GeneratedThemesEntryButton extends StatefulWidget {
  const GeneratedThemesEntryButton({required this.theme, super.key});

  final Host4RuntimeTheme theme;

  @override
  State<GeneratedThemesEntryButton> createState() =>
      _GeneratedThemesEntryButtonState();
}

class _GeneratedThemesEntryButtonState
    extends State<GeneratedThemesEntryButton> {
  late final GeneratedThemesEntryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GeneratedThemesEntryViewModel()..start();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Host4Button(
              label: '已生成主题',
              content: Host4ButtonContent.iconLeft,
              icon: Icons.palette_outlined,
              variant: Host4ButtonVariant.secondary,
              expanded: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GeneratedThemeListPage(),
                ),
              ),
            ),
            if (_viewModel.hasUnread)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.theme.colors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class GeneratedThemeListPage extends StatefulWidget {
  const GeneratedThemeListPage({super.key});

  @override
  State<GeneratedThemeListPage> createState() => _GeneratedThemeListPageState();
}

class _GeneratedThemeListPageState extends State<GeneratedThemeListPage> {
  late final GeneratedThemeListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GeneratedThemeListViewModel()..start();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final records = _viewModel.records;

        return Scaffold(
          backgroundColor: theme.colors.pageBackground,
          appBar: AppBar(
            backgroundColor: theme.colors.surface,
            title: Text(
              '已生成主题',
              style: theme.typography.heading.toTextStyle(
                theme.colors.textPrimary,
              ),
            ),
            iconTheme: IconThemeData(color: theme.colors.textPrimary),
          ),
          body: records.isEmpty
              ? Center(
                  child: Text(
                    '还没有生成过主题',
                    style: theme.typography.body.toTextStyle(
                      theme.colors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(theme.spacing.page),
                  itemCount: records.length,
                  separatorBuilder: (context, i) =>
                      SizedBox(height: theme.spacing.sm),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _SwipeActionTile(
                      key: ValueKey(record.jobId),
                      actionWidth: 96,
                      action: _DeleteAction(
                        onTap: () => _viewModel.deleteRecord(record),
                      ),
                      child: _JobListTile(
                        record: record,
                        onTap: record.status.isTerminal
                            ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GeneratedThemeDetailPage(
                                      record: record,
                                    ),
                                  ),
                                );
                                _viewModel.refresh();
                              }
                            : null,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class GeneratedThemeDetailPage extends StatefulWidget {
  const GeneratedThemeDetailPage({super.key, required this.record});

  final ThemeJobRecord record;

  @override
  State<GeneratedThemeDetailPage> createState() =>
      _GeneratedThemeDetailPageState();
}

class _GeneratedThemeDetailPageState extends State<GeneratedThemeDetailPage> {
  late final GeneratedThemeDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GeneratedThemeDetailViewModel(record: widget.record)
      ..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalTheme = context.host4Theme;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final record = widget.record;
        final tokens = record.tokens;
        final theme = _viewModel.preview ?? globalTheme;
        final hasImages =
            record.generateImages &&
            (record.localImagePaths != null || record.imageUrls != null);

        return Scaffold(
          backgroundColor: theme.colors.pageBackground,
          appBar: AppBar(
            backgroundColor: theme.colors.surface,
            title: Text(
              '主题详情',
              style: theme.typography.heading.toTextStyle(
                theme.colors.textPrimary,
              ),
            ),
            iconTheme: IconThemeData(color: theme.colors.textPrimary),
          ),
          body: (_viewModel.loading || _viewModel.applying)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (_viewModel.applying) ...[
                        SizedBox(height: theme.spacing.md),
                        Text(
                          '下载图片中...',
                          style: theme.typography.caption.toTextStyle(
                            theme.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(theme.spacing.page),
                  children: [
                    Container(
                      padding: EdgeInsets.all(theme.spacing.card),
                      decoration: BoxDecoration(
                        color: theme.colors.surface,
                        borderRadius: BorderRadius.circular(theme.radius.md),
                        border: Border.all(color: theme.colors.borderDefault),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '提示词',
                                style: theme.typography.label.toTextStyle(
                                  theme.colors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (record.generateImages)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: theme.spacing.sm,
                                    vertical: theme.spacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colors.brandPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      theme.radius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    '含图片',
                                    style: theme.typography.caption.toTextStyle(
                                      theme.colors.brandPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: theme.spacing.xs),
                          Text(
                            record.prompt,
                            style: theme.typography.body.toTextStyle(
                              theme.colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: theme.spacing.sm),
                          Text(
                            _formatDate(record.createdAt),
                            style: theme.typography.caption.toTextStyle(
                              theme.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (record.status == ThemeJobStatus.failed &&
                        record.error != null) ...[
                      SizedBox(height: theme.spacing.md),
                      Container(
                        padding: EdgeInsets.all(theme.spacing.card),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(theme.radius.md),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          record.error!,
                          style: theme.typography.caption.toTextStyle(
                            Colors.red,
                          ),
                        ),
                      ),
                    ],
                    if (tokens != null && _viewModel.preview != null) ...[
                      SizedBox(height: theme.spacing.md),
                      _ModeToggle(
                        mode: _viewModel.mode,
                        onChanged: _viewModel.changeMode,
                        theme: theme,
                      ),
                      SizedBox(height: theme.spacing.md),
                      _ThemeColorPreview(
                        preview: _viewModel.preview!,
                        theme: theme,
                      ),
                      SizedBox(height: theme.spacing.md),
                      _ThemeDebugSection(
                        preview: _viewModel.preview!,
                        theme: theme,
                      ),
                      SizedBox(height: theme.spacing.lg),
                      _PreviewButton(
                        label: hasImages ? '使用此主题（含图片）' : '使用此主题',
                        icon: Icons.check_circle_outline,
                        theme: theme,
                        expanded: true,
                        onPressed: () async {
                          await _viewModel.applyTheme(context);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: theme.spacing.sm),
                    ],
                    _PreviewButton(
                      label: '删除',
                      icon: Icons.delete_outline,
                      theme: theme,
                      variant: Host4ButtonVariant.ghost,
                      expanded: true,
                      onPressed: () async {
                        await _viewModel.deleteRecord();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class GeneratedThemesEntryViewModel extends ChangeNotifier {
  void start() {
    ThemeJobPoller.instance.addListener(_handleChanged);
  }

  bool get hasUnread => ThemeJobStore.instance.hasUnread;

  void _handleChanged() => notifyListeners();

  @override
  void dispose() {
    ThemeJobPoller.instance.removeListener(_handleChanged);
    super.dispose();
  }
}

class GeneratedThemeListViewModel extends ChangeNotifier {
  void start() {
    ThemeJobPoller.instance.addListener(_handleChanged);
    ThemeJobStore.instance.markAllRead().then((_) {
      notifyListeners();
    });
  }

  List<ThemeJobRecord> get records => ThemeJobStore.instance.records;

  Future<void> deleteRecord(ThemeJobRecord record) async {
    await ThemeJobStore.instance.delete(record.jobId);
    ThemeJobPoller.instance.reconcile();
    notifyListeners();
  }

  void refresh() => notifyListeners();

  void _handleChanged() => notifyListeners();

  @override
  void dispose() {
    ThemeJobPoller.instance.removeListener(_handleChanged);
    super.dispose();
  }
}

class GeneratedThemeDetailViewModel extends ChangeNotifier {
  GeneratedThemeDetailViewModel({required this.record});

  final ThemeJobRecord record;

  String _mode = 'light';
  Host4RuntimeTheme? _preview;
  bool _loading = false;
  bool _applying = false;

  String get mode => _mode;
  Host4RuntimeTheme? get preview => _preview;
  bool get loading => _loading;
  bool get applying => _applying;

  void initialize() {
    if (record.tokens != null) {
      loadPreview();
    }
  }

  Future<void> changeMode(String mode) async {
    _mode = mode;
    notifyListeners();
    await loadPreview();
  }

  Future<void> loadPreview() async {
    final tokens = record.tokens;
    if (tokens == null) return;

    _loading = true;
    notifyListeners();
    try {
      _preview = await Host4ThemeLoader.loadFromMap(tokens, mode: _mode);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> applyTheme(BuildContext context) async {
    final tokens = record.tokens;
    if (tokens == null) return;

    Host4ThemeImages? images;
    if (record.generateImages) {
      final local = record.localImagePaths;
      final urls = record.imageUrls;

      if (local != null && local.isNotEmpty) {
        images = _buildImagesForMode(_mode, local);
      } else if (urls != null && urls.isNotEmpty) {
        _applying = true;
        notifyListeners();
        try {
          final downloaded = await _downloadImages(urls);
          record.localImagePaths = downloaded;
          await ThemeJobStore.instance.update(record);
          images = _buildImagesForMode(_mode, downloaded);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('图片下载失败: $e')));
          }
          rethrow;
        } finally {
          _applying = false;
          notifyListeners();
        }
      }
    }

    if (!context.mounted) return;
    await context.host4ThemeManager.applyGeneratedTheme(
      tokens,
      mode: _mode,
      images: images,
    );
  }

  Future<void> deleteRecord() async {
    await ThemeJobStore.instance.delete(record.jobId);
    ThemeJobPoller.instance.reconcile();
  }

  Future<Map<String, String>> _downloadImages(
    Map<String, String> imageUrls,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}/generated_themes/${record.jobId}/images',
    );
    await dir.create(recursive: true);

    final result = <String, String>{};
    for (final entry in imageUrls.entries) {
      final url = '${record.serverUrl}${entry.value}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final filename = entry.value.split('/').last;
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        result[entry.key] = file.path;
      }
    }
    return result;
  }

  Host4ThemeImages _buildImagesForMode(String mode, Map<String, String> paths) {
    String get(String key) =>
        paths['${key}_$mode'] ?? paths['${key}_light'] ?? '';

    return Host4ThemeImages(
      pageBackground: get('pageBackground'),
      heroBanner: get('heroBanner'),
      spotIllustration: get('spotIllustration'),
      tabItems: List.generate(
        3,
        (i) => Host4TabItemImages(
          normal: paths['tab_${i}_$mode'] ?? paths['tab_${i}_light'] ?? '',
          selected:
              paths['tab_${i}_selected_$mode'] ??
              paths['tab_${i}_selected_light'] ??
              '',
        ),
      ),
    );
  }
}

class _JobListTile extends StatelessWidget {
  const _JobListTile({required this.record, this.onTap});

  final ThemeJobRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    final (statusLabel, statusColor) = switch (record.status) {
      ThemeJobStatus.pending => ('颜色生成中...', theme.colors.textSecondary),
      ThemeJobStatus.colorsDone => ('颜色已完成', theme.colors.brandAccent),
      ThemeJobStatus.imagesGenerating => ('图片生成中...', theme.colors.brandAccent),
      ThemeJobStatus.done => ('已生成', theme.colors.success),
      ThemeJobStatus.failed => ('生成失败', Colors.red),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(theme.spacing.card),
        decoration: BoxDecoration(
          color: theme.colors.surface,
          borderRadius: BorderRadius.circular(theme.radius.md),
          border: Border.all(color: theme.colors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.prompt,
                    style: theme.typography.body.toTextStyle(
                      theme.colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!record.isRead && record.status.isTerminal)
                  Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.only(left: theme.spacing.sm),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            SizedBox(height: theme.spacing.xs),
            Row(
              children: [
                Text(
                  statusLabel,
                  style: theme.typography.caption.toTextStyle(statusColor),
                ),
                const Spacer(),
                Text(
                  _formatDate(record.createdAt),
                  style: theme.typography.caption.toTextStyle(
                    theme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAction extends StatelessWidget {
  const _DeleteAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Material(
      color: Colors.red.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(theme.radius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.md),
        onTap: onTap,
        child: const SizedBox(
          width: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 22),
              _DeleteLabel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteLabel extends StatelessWidget {
  const _DeleteLabel();

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Padding(
      padding: EdgeInsets.only(top: theme.spacing.xs),
      child: Text(
        '删除',
        style: theme.typography.caption.toTextStyle(Colors.white),
      ),
    );
  }
}

class _SwipeActionTile extends StatefulWidget {
  const _SwipeActionTile({
    required this.child,
    required this.action,
    required this.actionWidth,
    super.key,
  });

  final Widget child;
  final Widget action;
  final double actionWidth;

  @override
  State<_SwipeActionTile> createState() => _SwipeActionTileState();
}

class _SwipeActionTileState extends State<_SwipeActionTile> {
  double _dragExtent = 0;
  bool _isOpen = false;

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = _dragExtent + details.delta.dx;
    setState(() {
      _dragExtent = next.clamp(-widget.actionWidth, 0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen =
        _dragExtent.abs() > widget.actionWidth * 0.45 ||
        details.primaryVelocity != null && details.primaryVelocity! < -250;
    setState(() {
      _isOpen = shouldOpen;
      _dragExtent = shouldOpen ? -widget.actionWidth : 0;
    });
  }

  void _close() {
    if (!_isOpen && _dragExtent == 0) return;
    setState(() {
      _isOpen = false;
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.md),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: widget.action,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(_dragExtent, 0, 0),
              child: widget.child,
            ),
          ),
          if (_isOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: widget.actionWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
        ],
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
                .map((p) => _ColorChip(label: p.$1, color: p.$2, theme: theme))
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
              _DebugRow(label: 'id', value: preview.meta.id, theme: t),
              _DebugRow(label: 'name', value: preview.meta.name, theme: t),
              _DebugRow(label: 'schema', value: preview.meta.schema, theme: t),
              _DebugRow(label: 'mode', value: preview.meta.mode, theme: t),
              _DebugRow(
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
              _DebugRow(
                label: 'pageBackground',
                value: preview.images.pageBackground,
                theme: t,
              ),
              _DebugRow(
                label: 'heroBanner',
                value: preview.images.heroBanner,
                theme: t,
              ),
              _DebugRow(
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

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.color,
    required this.theme,
  });

  final String label;
  final Color color;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.sm),
      decoration: BoxDecoration(
        color: theme.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(theme.radius.sm),
            ),
          ),
          SizedBox(width: theme.spacing.sm),
          Text(
            label,
            style: theme.typography.caption.toTextStyle(
              theme.colors.textPrimary,
            ),
          ),
        ],
      ),
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
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
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

class _DebugRow extends StatelessWidget {
  const _DebugRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final Host4RuntimeTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              label,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.typography.caption.toTextStyle(
                theme.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
