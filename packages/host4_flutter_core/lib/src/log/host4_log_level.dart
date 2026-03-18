/// Severity levels for log messages, ordered from least to most severe.
///
/// [silent] is a special sentinel used in tag overrides to suppress all output
/// for a specific tag — it is never passed to [Host4LogSink.write].
enum Host4LogLevel {
  trace,
  debug,
  info,
  warn,
  error,
  silent,
}
