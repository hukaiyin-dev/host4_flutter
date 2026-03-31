import 'package:collection/collection.dart';

final class Host4Event {
  Host4Event({
    required String name,
    Map<String, Object?> properties = const <String, Object?>{},
    required DateTime timestamp,
  })  : name = name.trim(),
        properties = UnmodifiableMapView<String, Object?>(
          Map<String, Object?>.from(properties),
        ),
        timestamp = timestamp.toUtc();

  final String name;
  final Map<String, Object?> properties;
  final DateTime timestamp;

  static const DeepCollectionEquality _propertiesEquality =
      DeepCollectionEquality();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Host4Event &&
            name == other.name &&
            timestamp == other.timestamp &&
            _propertiesEquality.equals(properties, other.properties);
  }

  @override
  int get hashCode => Object.hash(
        name,
        timestamp,
        _propertiesEquality.hash(properties),
      );
}
