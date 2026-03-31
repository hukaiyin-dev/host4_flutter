import '../json/host4_json.dart';

class Host4ReferenceResolver {
  const Host4ReferenceResolver(this.root);

  final Map<String, dynamic> root;

  Map<String, dynamic> resolveMap(Map<String, dynamic> input) {
    return input.map<String, dynamic>(
      (key, value) => MapEntry(key, _resolve(value)),
    );
  }

  dynamic _resolve(dynamic value, [List<String>? resolvingPaths]) {
    final stack = resolvingPaths ?? <String>[];

    if (value is Map<String, dynamic>) {
      return value.map<String, dynamic>(
        (key, entry) => MapEntry(key, _resolve(entry, stack)),
      );
    }
    if (value is List<dynamic>) {
      return value
          .map((entry) => _resolve(entry, stack))
          .toList(growable: false);
    }
    if (value is! String) {
      return value;
    }

    final match = RegExp(r'^\{(.+)\}$').firstMatch(value);
    if (match == null) {
      return value;
    }

    final reference = match.group(1)!;
    if (stack.contains(reference)) {
      final chain = [...stack, reference].join(' -> ');
      throw FormatException('Circular token reference detected: $chain');
    }

    final target = _lookup(reference);
    stack.add(reference);
    try {
      return _resolve(target, stack);
    } finally {
      stack.removeLast();
    }
  }

  dynamic _lookup(String path) {
    try {
      return readJsonPath(root, path);
    } on FormatException {
      throw FormatException('Unknown token reference: $path');
    }
  }
}
