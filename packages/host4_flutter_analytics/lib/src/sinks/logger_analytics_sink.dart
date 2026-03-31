import 'dart:convert';

import 'package:host4_flutter_core/host4_flutter_core.dart';

import '../model/host4_event.dart';
import '../sink/host4_analytics_sink.dart';

final class LoggerAnalyticsSink implements Host4AnalyticsSink {
  LoggerAnalyticsSink({
    required Host4LogSink logger,
    this.level = Host4LogLevel.info,
    this.tag = 'Analytics',
  }) : _logger = logger;

  final Host4LogSink _logger;
  final Host4LogLevel level;
  final String tag;

  @override
  void emit(Host4Event event) {
    _logger.write(
      level,
      tag,
      '${event.name} ${_sortedPropertiesJson(event.properties)}',
    );
  }

  String _sortedPropertiesJson(Map<String, Object?> properties) {
    final sortedKeys = properties.keys.toList()..sort();
    final normalized = <String, Object?>{};
    for (final key in sortedKeys) {
      normalized[key] = properties[key];
    }
    return jsonEncode(normalized);
  }
}
