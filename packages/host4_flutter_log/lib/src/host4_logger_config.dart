import 'package:flutter/foundation.dart';
import 'package:host4_flutter_core/host4_flutter_core.dart';

/// Configuration for [Host4Logger].
///
/// Call [Host4Logger.configure] once at app startup (after
/// WidgetsFlutterBinding.ensureInitialized).
///
/// Example:
/// ```dart
/// await Host4Logger.configure(Host4LoggerConfig(
///   minimumLevel: Host4LogLevel.debug,
///   fileEnabled: !kDebugMode,
///   tagOverrides: {'NET': Host4LogLevel.silent},
/// ));
/// ```
class Host4LoggerConfig {
  Host4LoggerConfig({
    this.minimumLevel = Host4LogLevel.debug,
    this.tagOverrides = const {},
    bool? consoleEnabled,
    this.fileEnabled = false,
    this.fileName = 'host4_flutter.log',
  }) : consoleEnabled = consoleEnabled ?? kDebugMode;

  /// Global minimum level. Messages below this level are dropped.
  final Host4LogLevel minimumLevel;

  /// Per-tag overrides. Use [Host4LogLevel.silent] to suppress a tag entirely.
  final Map<String, Host4LogLevel> tagOverrides;

  /// Whether to print to the debug console. Defaults to [kDebugMode].
  final bool consoleEnabled;

  /// Whether to write logs to a local file. Defaults to false.
  /// Enable this in release builds so logs can be exported.
  final bool fileEnabled;

  /// Name of the log file inside the app's Documents directory.
  final String fileName;
}
