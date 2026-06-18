int gmacroToInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

String gmacroToString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

double gmacroToDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}
