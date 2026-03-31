import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

const _channel = MethodChannel('host4_flutter_demo/log_share');

/// Shares [file] using the platform-appropriate mechanism.
///
/// On iOS, delegates to the native log-share channel so the app can
/// present a share sheet from the native side with full access to
/// AirDrop and other iOS share targets.
///
/// On other platforms, uses the cross-platform share_plus package.
Future<void> shareLogFile(File file, String fileName) async {
  if (Platform.isIOS) {
    final text = await file.readAsString();
    await _channel.invokeMethod<void>('shareText', <String, Object?>{
      'text': text.isEmpty ? 'No logs yet.' : text,
      'subject': fileName,
    });
  } else {
    final bytes = await file.readAsBytes();
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/plain', name: fileName)],
      subject: fileName,
      fileNameOverrides: [fileName],
    );
  }
}
