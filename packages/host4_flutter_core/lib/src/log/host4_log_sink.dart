import 'host4_log_level.dart';

/// Abstraction for any log output backend.
///
/// Other packages (e.g. analytics) depend on this interface rather than the
/// concrete [Host4Logger] from host4_flutter_log, keeping the dependency
/// direction clean.
abstract interface class Host4LogSink {
  void write(
    Host4LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });
}
