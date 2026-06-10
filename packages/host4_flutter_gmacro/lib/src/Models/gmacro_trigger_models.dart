import 'gmacro_model_parsers.dart';

/// 扳机线性输出配置（对应 0x85 fetch / set）
///
/// [leftMode]/[rightMode]: 1=线性输出, 2=非线性输出
/// [leftThreshold]/[rightThreshold]: 1-255 (仅非线性输出时使用)
class LinearTriggerOutput {
  const LinearTriggerOutput({
    required this.leftMode,
    required this.leftThreshold,
    required this.rightMode,
    required this.rightThreshold,
  });

  final int leftMode;
  final int leftThreshold;
  final int rightMode;
  final int rightThreshold;

  factory LinearTriggerOutput.fromMap(Map<dynamic, dynamic> map) {
    return LinearTriggerOutput(
      leftMode: gmacroToInt(map['leftMode']),
      leftThreshold: gmacroToInt(map['leftThreshold']),
      rightMode: gmacroToInt(map['rightMode']),
      rightThreshold: gmacroToInt(map['rightThreshold']),
    );
  }

  @override
  String toString() {
    return 'LinearTriggerOutput('
        'leftMode: $leftMode, leftThreshold: $leftThreshold, '
        'rightMode: $rightMode, rightThreshold: $rightThreshold)';
  }
}
