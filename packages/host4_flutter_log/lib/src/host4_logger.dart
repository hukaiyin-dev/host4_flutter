import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:host4_flutter_core/host4_flutter_core.dart';
import 'package:path_provider/path_provider.dart';

import 'host4_logger_config.dart';

/// A tagged logger instance. Create one per module or class.
///
/// Usage:
/// ```dart
/// final _log = Host4Logger('Theme');
///
/// _log.info('Theme applied: default');
/// _log.warn('Image not found: hero_banner.png');
/// _log.error('Parse failed', error: e, stackTrace: s);
/// ```
class Host4Logger implements Host4LogSink {
  Host4Logger(this.tag);

  /// The tag that identifies this logger's module (e.g. 'NET', 'Theme').
  final String tag;

  // ── Global state ──────────────────────────────────────────────────────────

  static var _config = Host4LoggerConfig();

  /// Cached absolute path to the log file. Set by [configure] when
  /// fileEnabled is true. Null means file output is inactive.
  static String? _logFilePath;

  /// Configures the global logger. Call once at app startup, after
  /// WidgetsFlutterBinding.ensureInitialized(), before logging anything.
  static Future<void> configure(Host4LoggerConfig config) async {
    _config = config;
    _logFilePath = null;
    if (config.fileEnabled) {
      final dir = await getApplicationDocumentsDirectory();
      _logFilePath = '${dir.path}/${config.fileName}';
    }
  }

  // ── Instance log methods ──────────────────────────────────────────────────

  void trace(String message, {Object? error, StackTrace? stackTrace}) =>
      write(Host4LogLevel.trace, tag, message,
          error: error, stackTrace: stackTrace);

  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      write(Host4LogLevel.debug, tag, message,
          error: error, stackTrace: stackTrace);

  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      write(Host4LogLevel.info, tag, message,
          error: error, stackTrace: stackTrace);

  void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      write(Host4LogLevel.warn, tag, message,
          error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      write(Host4LogLevel.error, tag, message,
          error: error, stackTrace: stackTrace);

  // ── Host4LogSink ──────────────────────────────────────────────────────────

  @override
  void write(
    Host4LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == Host4LogLevel.silent) return;

    final effectiveMinimum = _config.tagOverrides[tag] ?? _config.minimumLevel;
    if (level.index < effectiveMinimum.index) return;

    final line = _format(level, tag, message, error, stackTrace);

    if (_config.consoleEnabled) {
      debugPrint(line);
    }

    if (_config.fileEnabled && _logFilePath != null) {
      _appendToFile(line);
    }
  }

  // ── File management (static) ───────────────────────────────────────────────

  /// Returns the log file if it exists, or null if file logging is disabled
  /// or no file has been written yet.
  static Future<File?> exportLogFile() async {
    final path = await _resolvedLogFilePath();
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  /// Clears the contents of the log file without deleting it.
  static Future<void> clearLogFile() async {
    final path = await _resolvedLogFilePath();
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) {
      await file.writeAsString('');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _format(
    Host4LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';

    var line = '$time ${_levelLabel(level)} [$tag] $message';
    if (error != null) line += '\n  error: $error';
    if (stackTrace != null) line += '\n  stack: $stackTrace';
    return line;
  }

  static String _levelLabel(Host4LogLevel level) => switch (level) {
        Host4LogLevel.trace => 'T',
        Host4LogLevel.debug => 'D',
        Host4LogLevel.info => 'I',
        Host4LogLevel.warn => 'W',
        Host4LogLevel.error => 'E',
        Host4LogLevel.silent => ' ',
      };

  static void _appendToFile(String line) {
    try {
      File(_logFilePath!).writeAsStringSync(
        '$line\n',
        mode: FileMode.append,
        flush: false,
      );
    } catch (_) {
      // Never let a logging failure crash the app.
    }
  }

  /// Returns [_logFilePath] if already set, or resolves it on demand
  /// (useful for exportLogFile / clearLogFile even when fileEnabled is false).
  static Future<String?> _resolvedLogFilePath() async {
    if (_logFilePath != null) return _logFilePath;
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${_config.fileName}';
  }
}
