dynamic readJsonPath(Map<String, dynamic> json, String path) {
  dynamic current = json;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic> && current.containsKey(segment)) {
      current = current[segment];
      continue;
    }
    throw FormatException('Missing json path: $path');
  }
  return current;
}

Map<String, dynamic> readJsonMap(Map<String, dynamic> json, String path) {
  final value = readJsonPath(json, path);
  if (value is! Map) {
    throw FormatException('Expected object at $path.');
  }
  return value.cast<String, dynamic>();
}

String readJsonString(Map<String, dynamic> json, String path) {
  final value = readJsonPath(json, path);
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }
  return value;
}

List<String> readJsonStringList(Map<String, dynamic> json, String path) {
  final value = readJsonPath(json, path);
  if (value is! List) {
    throw FormatException('Expected string list at $path.');
  }
  return value.map((item) => item.toString()).toList(growable: false);
}

double readJsonDouble(
  Map<String, dynamic> json,
  String path, {
  double? fallback,
}) {
  final dynamic value;
  try {
    value = readJsonPath(json, path);
  } on FormatException {
    if (fallback != null) {
      return fallback;
    }
    rethrow;
  }

  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Expected number at $path.');
}
