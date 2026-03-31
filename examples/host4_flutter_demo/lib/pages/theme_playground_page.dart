import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';
import 'package:http/http.dart' as http;

import '../features/generated_themes/generated_themes_feature.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme_job.dart';
import '../theme_job_poller.dart';
import 'local_themes_page.dart';

final _log = Host4Logger('ThemePlayground');

class ThemePlaygroundPage extends StatefulWidget {
  const ThemePlaygroundPage({super.key});

  @override
  State<ThemePlaygroundPage> createState() => _ThemePlaygroundPageState();
}

class _ThemePlaygroundPageState extends State<ThemePlaygroundPage> {
  late final TextEditingController _promptController;
  late final TextEditingController _serverUrlController;
  String? _localizedDefaultPrompt;
  bool _isGenerating = false;
  bool _generateImages = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _serverUrlController = TextEditingController(
      text: 'http://hukaiyindeMacBook-Pro.local:8000',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPrompt = AppLocalizations.of(context).promptExampleText;
    if (_promptController.text.isEmpty ||
        _promptController.text == _localizedDefaultPrompt) {
      _promptController.value = TextEditingValue(
        text: nextPrompt,
        selection: TextSelection.collapsed(offset: nextPrompt.length),
      );
    }
    _localizedDefaultPrompt = nextPrompt;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final serverUrl = _serverUrlController.text.trim();
    final prompt = _promptController.text.trim();
    if (serverUrl.isEmpty || prompt.isEmpty) return;

    _log.info('generate_theme: POST $serverUrl/generate_theme');
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/generate_theme'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'generate_images': _generateImages,
            }),
          )
          .timeout(const Duration(seconds: 30));

      _log.info('generate_theme: status=${response.statusCode}');

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        setState(
          () => _error =
              body['detail']?.toString() ?? 'Error ${response.statusCode}',
        );
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final jobId = body['job_id'] as String;
      _log.info('generate_theme: job created, id=$jobId');

      final record = ThemeJobRecord(
        jobId: jobId,
        prompt: prompt,
        serverUrl: serverUrl,
        createdAt: DateTime.now(),
        generateImages: _generateImages,
      );
      await ThemeJobStore.instance.add(record);
      await ThemeJobPoller.instance.pollNow();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('主题生成中，完成后可在「已生成主题」列表查看')),
      );
    } catch (e, st) {
      _log.error('generate_theme: $e\n$st');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final manager = context.host4ThemeManager;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          theme.spacing.page,
          0,
          theme.spacing.page,
          theme.spacing.page,
        ),
        children: [
          Host4SectionHeader(
            title: l10n.currentThemeTitle(theme.meta.name),
            subtitle: l10n.currentThemeSubtitle,
          ),
          SizedBox(height: theme.spacing.section),
          // ── 本地主题 ──
          Host4SectionHeader(title: '本地主题', subtitle: '浏览并应用内置主题'),
          SizedBox(height: theme.spacing.md),
          Host4Button(
            label: '浏览本地主题',
            content: Host4ButtonContent.iconLeft,
            icon: Icons.grid_view_rounded,
            variant: Host4ButtonVariant.secondary,
            expanded: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocalThemeListPage(catalog: manager.catalog),
              ),
            ),
          ),
          SizedBox(height: theme.spacing.section),

          // ── AI 主题 ──
          Host4SectionHeader(title: 'AI 主题', subtitle: '通过提示词生成新主题'),
          SizedBox(height: theme.spacing.md),
          Host4Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Host4TextField(
                  controller: _serverUrlController,
                  hintText: 'http://hukaiyindeMacBook-Pro.local:8000',
                ),
                SizedBox(height: theme.spacing.sm),
                Host4TextField(
                  controller: _promptController,
                  hintText: l10n.promptHint,
                  maxLines: 4,
                ),
                SizedBox(height: theme.spacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '生成图片',
                      style: theme.typography.caption.toTextStyle(
                        theme.colors.textSecondary,
                      ),
                    ),
                    Switch.adaptive(
                      value: _generateImages,
                      activeThumbColor: theme.colors.brandPrimary,
                      activeTrackColor: theme.colors.brandPrimary.withValues(
                        alpha: 0.4,
                      ),
                      onChanged: (v) => setState(() => _generateImages = v),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: theme.typography.caption.toTextStyle(Colors.red),
                  ),
                  SizedBox(height: theme.spacing.sm),
                ],
                Host4Button(
                  label: _isGenerating ? '生成中...' : l10n.generateThemeButton,
                  content: Host4ButtonContent.iconLeft,
                  icon: Icons.auto_awesome_outlined,
                  expanded: true,
                  onPressed: _isGenerating
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _generate();
                        },
                ),
                SizedBox(height: theme.spacing.sm),
                GeneratedThemesEntryButton(theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
