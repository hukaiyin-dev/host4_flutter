import 'package:host4_flutter_analytics/host4_flutter_analytics.dart';
import 'package:host4_flutter_core/host4_flutter_core.dart';
import 'package:test/test.dart';

void main() {
  test('track emits event to every configured sink', () async {
    final primarySink = _SpyAnalyticsSink();
    final secondarySink = _SpyAnalyticsSink();
    final timestamp = DateTime.utc(2026, 3, 27, 12, 0);
    final client = Host4AnalyticsClient(
      sinks: [primarySink, secondarySink],
      now: () => timestamp,
    );

    await client.track(
      'page_view',
      properties: {'page': 'home', 'loggedIn': true},
    );

    expect(primarySink.events, hasLength(1));
    expect(secondarySink.events, hasLength(1));
    expect(primarySink.events.single, secondarySink.events.single);
    expect(
      primarySink.events.single,
      Host4Event(
        name: 'page_view',
        properties: {'page': 'home', 'loggedIn': true},
        timestamp: timestamp,
      ),
    );
  });

  test('track rejects blank event names', () async {
    final client = Host4AnalyticsClient(
      sinks: const [],
      now: () => DateTime.utc(2026, 3, 27),
    );

    await expectLater(
      () => client.track('   '),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'Event name must not be blank.',
        ),
      ),
    );
  });

  test('logger analytics sink forwards event to Host4LogSink', () {
    final logger = _SpyLogSink();
    final sink = LoggerAnalyticsSink(logger: logger);

    sink.emit(
      Host4Event(
        name: 'page_view',
        properties: {'page': 'home', 'count': 1},
        timestamp: DateTime.utc(2026, 3, 27, 12, 0),
      ),
    );

    expect(logger.records, hasLength(1));
    expect(logger.records.single.level, Host4LogLevel.info);
    expect(logger.records.single.tag, 'Analytics');
    expect(logger.records.single.message, 'page_view {"count":1,"page":"home"}');
  });
}

final class _SpyAnalyticsSink implements Host4AnalyticsSink {
  final List<Host4Event> events = <Host4Event>[];

  @override
  void emit(Host4Event event) {
    events.add(event);
  }
}

final class _SpyLogSink implements Host4LogSink {
  final List<_LogRecord> records = <_LogRecord>[];

  @override
  void write(
    Host4LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    records.add(
      _LogRecord(
        level: level,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

final class _LogRecord {
  const _LogRecord({
    required this.level,
    required this.tag,
    required this.message,
    required this.error,
    required this.stackTrace,
  });

  final Host4LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}
