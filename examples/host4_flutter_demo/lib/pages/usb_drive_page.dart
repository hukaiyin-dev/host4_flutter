import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:host4_flutter_ui/host4_flutter_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../platform/usb_drive_channel.dart';
import '../widgets/debug_row.dart';

class UsbDrivePage extends StatefulWidget {
  const UsbDrivePage({super.key});

  @override
  State<UsbDrivePage> createState() => _UsbDrivePageState();
}

class _UsbDrivePageState extends State<UsbDrivePage> {
  bool _picking = false;
  Map<Object?, Object?>? _pickedFile;

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    if (!Platform.isIOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.usbDrivePickUnsupported)),
      );
      return;
    }

    setState(() => _picking = true);
    try {
      final result = await pickDocument();
      if (!mounted || result == null) return;
      setState(() => _pickedFile = result);
    } on PlatformException catch (error) {
      if (!mounted || error.code == 'cancelled') return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.usbDrivePickFailed}: ${error.message ?? error.code}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.host4Theme;
    final pickedFile = _pickedFile;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        theme.spacing.page,
        0,
        theme.spacing.page,
        theme.spacing.page,
      ),
      children: [
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(l10n.usbDriveIntroTitle, role: Host4TextRole.heading),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.usbDriveIntroBody,
                colorRole: Host4TextColorRole.secondary,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(
                l10n.usbDriveIosStatusTitle,
                role: Host4TextRole.heading,
              ),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.usbDriveIosStatusBody,
                colorRole: Host4TextColorRole.secondary,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(
                l10n.usbDriveAndroidStatusTitle,
                role: Host4TextRole.heading,
              ),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.usbDriveAndroidStatusBody,
                colorRole: Host4TextColorRole.secondary,
              ),
            ],
          ),
        ),
        SizedBox(height: theme.spacing.md),
        Host4Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Host4Text(
                l10n.usbDriveActionTitle,
                role: Host4TextRole.heading,
              ),
              SizedBox(height: theme.spacing.sm),
              Host4Text(
                l10n.usbDriveActionBody,
                colorRole: Host4TextColorRole.secondary,
              ),
              SizedBox(height: theme.spacing.md),
              Host4Button(
                label: _picking
                    ? l10n.usbDrivePicking
                    : l10n.usbDrivePickButton,
                expanded: true,
                onPressed: _picking ? null : _pickFile,
              ),
            ],
          ),
        ),
        if (pickedFile != null) ...[
          SizedBox(height: theme.spacing.md),
          Host4Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Host4Text(
                  l10n.usbDrivePickedResultTitle,
                  role: Host4TextRole.heading,
                ),
                SizedBox(height: theme.spacing.md),
                DebugRow(
                  label: l10n.usbDrivePickedName,
                  value: '${pickedFile['name'] ?? '-'}',
                  theme: theme,
                ),
                DebugRow(
                  label: l10n.usbDrivePickedSize,
                  value: '${pickedFile['size'] ?? '-'}',
                  theme: theme,
                ),
                DebugRow(
                  label: l10n.usbDrivePickedPath,
                  value: '${pickedFile['path'] ?? '-'}',
                  theme: theme,
                ),
                SizedBox(height: theme.spacing.sm),
                Text(
                  l10n.usbDrivePickedPreview,
                  style: theme.typography.caption.toTextStyle(
                    theme.colors.textSecondary,
                  ),
                ),
                SizedBox(height: theme.spacing.xs),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(theme.spacing.md),
                  decoration: BoxDecoration(
                    color: theme.colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(theme.radius.md),
                    border: Border.all(color: theme.colors.borderDefault),
                  ),
                  child: SelectableText(
                    '${pickedFile['preview'] ?? '-'}',
                    style: theme.typography.body.toTextStyle(
                      theme.colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
