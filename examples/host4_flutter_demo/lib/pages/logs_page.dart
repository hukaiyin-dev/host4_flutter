import 'dart:io';

import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../platform/log_share_channel.dart';

final _log = Host4Logger('LogsPage');

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String? _content;
  File? _file;
  bool _loading = true;
  bool _exporting = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final file = await Host4Logger.exportLogFile();
    final content =
        file != null && file.existsSync() ? file.readAsStringSync() : null;
    if (!mounted) return;
    setState(() {
      _file = file;
      _content = (content?.isEmpty ?? true) ? null : content;
      _loading = false;
    });
    if (_content != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _export() async {
    if (_exporting) return;

    final l10n = AppLocalizations.of(context);
    _log.info('Export logs');

    setState(() => _exporting = true);
    try {
      final file = await Host4Logger.exportLogFile();
      if (!mounted) return;

      if (file == null || !file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.logsExportUnavailable)),
        );
        return;
      }

      setState(() => _file = file);
      await shareLogFile(file, 'host4_flutter_logs.txt');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logsExportSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logsExportFailed)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logsClearConfirmTitle),
        content: Text(l10n.logsClearConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logsClearConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Host4Logger.clearLogFile();
    setState(() => _content = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return Host4PageScaffold(
      useSafeArea: false,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: l10n.logsPageTitle,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.components.navigationBar.icon,
                  size: 20,
                ),
              ),
              trailing: GestureDetector(
                onTap: _confirmClear,
                child: Text(
                  l10n.logsClearButton,
                  style: theme.typography.label.toTextStyle(
                    theme.colors.warning,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.page,
                theme.spacing.sm,
                theme.spacing.page,
                theme.spacing.md,
              ),
              child: Host4Button(
                label: l10n.logsExportButton,
                content: Host4ButtonContent.iconLeft,
                icon: Icons.ios_share_rounded,
                expanded: true,
                onPressed: !_loading && !_exporting && _file != null
                    ? _export
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_content == null) {
      return Center(
        child: Host4Text(
          l10n.logsEmptyMessage,
          colorRole: Host4TextColorRole.secondary,
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(theme.spacing.page),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText(
          _content!,
          style: theme.typography.caption
              .toTextStyle(theme.colors.textPrimary)
              .copyWith(
                fontFamily: 'Courier New',
                fontFamilyFallback: const ['Courier', 'monospace'],
                fontSize: 13,
                height: 1.6,
              ),
        ),
      ),
    );
  }
}
