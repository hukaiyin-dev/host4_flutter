import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:host4_flutter_analytics/host4_flutter_analytics.dart';

final class FirebaseAnalyticsSink implements Host4AnalyticsSink {
  FirebaseAnalyticsSink(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> emit(Host4Event event) {
    return _analytics.logEvent(
      name: event.name,
      parameters: _normalizeParameters(event),
    );
  }

  Map<String, Object> _normalizeParameters(Host4Event event) {
    final parameters = <String, Object>{
      'timestamp': event.timestamp.toIso8601String(),
    };

    event.properties.forEach((key, value) {
      if (value != null) {
        parameters[key] = value;
      }
    });

    return parameters;
  }
}
