import 'gmacro_model_parsers.dart';

class GmacroCurvePoint {
  const GmacroCurvePoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object?> toMap() => {'x': x, 'y': y};

  factory GmacroCurvePoint.fromMap(Map<dynamic, dynamic> map) {
    return GmacroCurvePoint(
      x: gmacroToDouble(map['x']),
      y: gmacroToDouble(map['y']),
    );
  }

  @override
  String toString() {
    return 'GmacroCurvePoint(x: $x, y: $y)';
  }
}
