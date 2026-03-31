import '../model/host4_event.dart';
import '../sink/host4_analytics_sink.dart';

typedef Host4Now = DateTime Function();

final class Host4AnalyticsClient {
  Host4AnalyticsClient({
    required Iterable<Host4AnalyticsSink> sinks,
    Host4Now? now,
  })  : _sinks = List<Host4AnalyticsSink>.unmodifiable(sinks),
        _now = now ?? DateTime.now;

  final List<Host4AnalyticsSink> _sinks;
  final Host4Now _now;

  Future<void> track(
    String name, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Event name must not be blank.');
    }

    final event = Host4Event(
      name: normalizedName,
      properties: properties,
      timestamp: _now(),
    );

    for (final sink in _sinks) {
      await Future<void>.sync(() => sink.emit(event));
    }
  }
}
