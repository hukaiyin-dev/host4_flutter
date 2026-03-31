import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:host4_flutter_analytics/host4_flutter_analytics.dart';
import 'package:host4_flutter_log/host4_flutter_log.dart';

import 'firebase_analytics_sink.dart';

Host4AnalyticsClient? _analytics;

Host4AnalyticsClient get appAnalytics {
  return _analytics ??= _buildAnalyticsClient();
}

void configureAnalytics({
  FirebaseAnalytics? firebaseAnalytics,
}) {
  _analytics = _buildAnalyticsClient(firebaseAnalytics: firebaseAnalytics);
}

Host4AnalyticsClient _buildAnalyticsClient({
  FirebaseAnalytics? firebaseAnalytics,
}) {
  final sinks = <Host4AnalyticsSink>[
    LoggerAnalyticsSink(logger: Host4Logger('Analytics')),
  ];

  if (firebaseAnalytics != null) {
    sinks.add(FirebaseAnalyticsSink(firebaseAnalytics));
  }

  return Host4AnalyticsClient(sinks: sinks);
}
