import 'package:flutter/material.dart';
import 'package:host4_flutter_gmacro_demo_ui/host4_flutter_gmacro_demo_ui.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sub_page_scaffold.dart';
import 'aivoice_test_page.dart';
import 'ios_tf_card_page.dart';
import 'silicone_overlay_page.dart';
import 'tester_page.dart';
import 'usb_drive_page.dart';
import 'web_emulator_poc_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.onResetToDefaults, super.key});

  final Future<void> Function() onResetToDefaults;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
        title: 'Web 模拟器 POC',
        subtitle: 'Nostalgist + mGBA 下载 core 验证',
        icon: Icons.sports_esports_outlined,
        color: Colors.indigo,
        minHeight: 220,
        builder: (_) => const WebEmulatorPocPage(),
      ),
      _LabEntry(
        title: '历史实验',
        subtitle: '已完成/已暂停',
        icon: Icons.history_outlined,
        color: theme.colors.textSecondary,
        minHeight: 210,
        builder: (_) => const _LegacyLabListPage(),
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

class _LegacyLabListPage extends StatelessWidget {
  const _LegacyLabListPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    return Host4PageScaffold(
      useSafeArea: false,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Host4NavigationBar(
              title: '历史实验',
              subtitle: '早期硬件验证项目',
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.page,
                vertical: theme.spacing.md,
              ),
              children: <Widget>[
                _LegacyLabTile(
                  icon: Icons.control_camera_outlined,
                  title: '硅胶贴片',
                  subtitle: '物理尺寸热区预研',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SiliconeOverlayPage(),
                    ),
                  ),
                ),
                _LegacyLabTile(
                  icon: Icons.record_voice_over_outlined,
                  title: 'AI Voice',
                  subtitle: '火山引擎 RTC 语音对话测试',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubPageScaffold(
                        title: 'AI Voice',
                        subtitle: '火山引擎 RTC 语音对话',
                        child: AiVoiceTestPage(),
                      ),
                    ),
                  ),
                ),
                _LegacyLabTile(
                  icon: Icons.usb_rounded,
                  title: l10n.labUsbDriveTitle,
                  subtitle: l10n.labUsbDriveSubtitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubPageScaffold(
                        title: l10n.usbDrivePageTitle,
                        subtitle: l10n.usbDrivePageSubtitle,
                        child: const UsbDrivePage(),
                      ),
                    ),
                  ),
                ),
                _LegacyLabTile(
                  icon: Icons.sd_storage_rounded,
                  title: 'iOS TF 卡',
                  subtitle: '按规则读取 TF 卡内的游戏',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubPageScaffold(
                        title: 'iOS TF 卡',
                        subtitle: '按规则读取 TF 卡内的游戏',
                        child: IosTfCardPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyLabTile extends StatelessWidget {
  const _LegacyLabTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.host4Theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(theme.radius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: theme.colors.textSecondary, size: 24),
              SizedBox(width: theme.spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Host4Text(title, role: Host4TextRole.body),
                    SizedBox(height: theme.spacing.xs),
                    Host4Text(
                      subtitle,
                      colorRole: Host4TextColorRole.secondary,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
