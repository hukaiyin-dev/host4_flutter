import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';
import 'package:host4_flutter_mfi/host4_flutter_mfi.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sub_page_scaffold.dart';
import 'aivoice_test_page.dart';
import 'gmacro/gmacro_entry_page.dart';
import 'gmacro/gmacro_placeholder_values.dart';
import 'gmacro/gmacro_session_page.dart';
import 'ios_tf_card_page.dart';
import 'silicone_overlay_page.dart';
import 'tester_page.dart';
import 'usb_drive_page.dart';

final _mfiLog = Host4Logger('HomeMFi');

class HomePage extends StatefulWidget {
  const HomePage({required this.onResetToDefaults, super.key});

  final Future<void> Function() onResetToDefaults;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Host4Mfi _mfi = Host4Mfi();
  StreamSubscription<MfiAccessoryEvent>? _mfiAccessorySub;
  bool _isMfiConnecting = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      unawaited(_subscribeMfiAccessoryEvents());
    }
  }

  @override
  void dispose() {
    _mfiAccessorySub?.cancel();
    super.dispose();
  }

  Future<void> _subscribeMfiAccessoryEvents() async {
    try {
      _mfiLog.info('Starting MFi accessory listener from home page.');
      await _mfi.start();
      await _mfi.updateProtocol(GmacroPlaceholderValues.mfiProtocolString);
      final connected = await _mfi.isAccessoryConnected();
      _mfiLog.info('Initial MFi accessory connected: $connected');
      if (!mounted) {
        return;
      }
      if (connected) {
        unawaited(_autoConnectMfiIfCurrentPage());
      }

      _mfiAccessorySub = _mfi.accessoryEvents.listen((event) {
        _mfiLog.info(
          'MFi accessory event: ${event.type.name}, name=${event.name}',
        );
        if (!mounted || event.type != MfiAccessoryEventType.connected) {
          return;
        }
        unawaited(_autoConnectMfiIfCurrentPage());
      });
    } catch (error) {
      _mfiLog.warn('MFi accessory listener failed: $error');
    }
  }

  Future<void> _autoConnectMfiIfCurrentPage() async {
    if (_isMfiConnecting) {
      return;
    }
    final route = ModalRoute.of(context);
    if (route?.isCurrent != true) {
      return;
    }
    await _connectMfi();
  }

  Future<void> _connectMfi() async {
    if (_isMfiConnecting) {
      return;
    }

    setState(() => _isMfiConnecting = true);
    try {
      _mfiLog.info('Auto connecting MFi from home page.');
      await _mfi.start();
      await _mfi.updateProtocol(GmacroPlaceholderValues.mfiProtocolString);
      final transport = await _mfi.connect(
        options: const <String, Object?>{'protocolType': 'gmacro'},
      );
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GmacroSessionPage(transport: transport),
        ),
      );
    } catch (error) {
      _mfiLog.warn('Auto connect MFi from home page failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isMfiConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final entries = <_LabEntry>[
      _LabEntry(
        title: 'GMacro 调试',
        subtitle: 'BLE / MFi 主链路 + OTA 测试',
        icon: Icons.gamepad_outlined,
        color: theme.colors.brandPrimary,
        minHeight: 220,
        builder: (_) => const GmacroEntryPage(),
      ),
      _LabEntry(
        title: '硅胶贴片',
        subtitle: '物理尺寸热区预研',
        icon: Icons.control_camera_outlined,
        color: theme.colors.brandAccent,
        minHeight: 210,
        builder: (_) => const SiliconeOverlayPage(),
      ),
      _LabEntry(
        title: l10n.labUsbDriveTitle,
        subtitle: l10n.labUsbDriveSubtitle,
        icon: Icons.usb_rounded,
        color: theme.colors.brandSecondary,
        minHeight: 260,
        builder: (_) => SubPageScaffold(
          title: l10n.usbDrivePageTitle,
          subtitle: l10n.usbDrivePageSubtitle,
          child: const UsbDrivePage(),
        ),
      ),
      _LabEntry(
        title: 'iOS TF 卡',
        subtitle: '按规则读取 TF 卡内的游戏',
        icon: Icons.sd_storage_rounded,
        color: theme.colors.brandSecondary,
        minHeight: 230,
        builder: (_) => const SubPageScaffold(
          title: 'iOS TF 卡',
          subtitle: '按规则读取 TF 卡内的游戏',
          child: IosTfCardPage(),
        ),
      ),
      _LabEntry(
        title: 'AI Voice',
        subtitle: '火山引擎 RTC 语音对话测试',
        icon: Icons.record_voice_over_outlined,
        color: Colors.deepPurple,
        minHeight: 210,
        builder: (_) => SubPageScaffold(
          title: 'AI Voice',
          subtitle: '火山引擎 RTC 语音对话',
          child: AiVoiceTestPage(),
        ),
      ),
      _LabEntry(
        title: l10n.labTesterTitle,
        subtitle: l10n.labTesterSubtitle,
        icon: Icons.science_outlined,
        color: theme.colors.warning,
        minHeight: 210,
        builder: (_) => SubPageScaffold(
          title: l10n.testerPageTitle,
          subtitle: l10n.testerPageSubtitle,
          child: TesterPage(onResetToDefaults: widget.onResetToDefaults),
        ),
      ),
    ];

    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];
    for (var index = 0; index < entries.length; index++) {
      final card = _LabCard(entry: entries[index]);
      if (index.isEven) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < leftColumn.length; i++) ...[
                    if (i > 0) SizedBox(height: theme.spacing.md),
                    leftColumn[i],
                  ],
                ],
              ),
            ),
            SizedBox(width: theme.spacing.md),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < rightColumn.length; i++) ...[
                    if (i > 0) SizedBox(height: theme.spacing.md),
                    rightColumn[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabEntry {
  const _LabEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.minHeight,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double minHeight;
  final WidgetBuilder builder;
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.entry});

  final _LabEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.card),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: entry.builder)),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(theme.radius.card),
            border: Border.all(color: theme.colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: entry.minHeight),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: entry.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(theme.radius.lg),
                    ),
                    child: Icon(entry.icon, color: entry.color, size: 28),
                  ),
                  SizedBox(height: theme.spacing.lg),
                  Host4Text(entry.title, role: Host4TextRole.heading),
                  SizedBox(height: theme.spacing.sm),
                  Host4Text(
                    entry.subtitle,
                    colorRole: Host4TextColorRole.secondary,
                  ),
                  SizedBox(height: theme.spacing.xxl),
                  SizedBox(height: theme.spacing.lg),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: theme.spacing.sm,
                          vertical: theme.spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            theme.radius.pill,
                          ),
                        ),
                        child: Text(
                          l10n.inspectButton,
                          style: theme.typography.caption.toTextStyle(
                            theme.colors.textSecondary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: theme.colors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
