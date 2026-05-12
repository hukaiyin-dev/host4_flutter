import 'transport_kind.dart';

class DeviceDescriptor {
  const DeviceDescriptor({
    required this.id,
    required this.name,
    required this.kind,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String name;
  final TransportKind kind;
  final Map<String, Object?> metadata;
}
