class DeviceScanQuery {
  const DeviceScanQuery({
    required this.serviceIds,
    this.hints = const <String, Object?>{},
  });

  final List<String> serviceIds;
  final Map<String, Object?> hints;
}
