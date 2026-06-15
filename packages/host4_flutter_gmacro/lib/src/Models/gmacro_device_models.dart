import 'gmacro_model_parsers.dart';

/// 设备版本信息（对应 0x80 fetchDeviceVersion）
///
/// 字段与 iOS `analyzeDeviceVersion` 对齐：
/// - [project]: 项目编码
/// - [protocol]: 协议版本
/// - [firmware]: 固件版本
/// - [hardware]: 硬件版本
class DeviceVersionPayload {
  const DeviceVersionPayload({
    required this.project,
    required this.protocol,
    required this.firmware,
    required this.hardware,
  });

  final String project;
  final String protocol;
  final String firmware;
  final String hardware;

  Map<String, Object?> toMap() => {
    'project': project,
    'protocol': protocol,
    'firmware': firmware,
    'hardware': hardware,
  };

  factory DeviceVersionPayload.fromMap(Map<dynamic, dynamic> map) {
    return DeviceVersionPayload(
      project: gmacroToString(map['project']),
      protocol: gmacroToString(map['protocol']),
      firmware: gmacroToString(map['firmware']),
      hardware: gmacroToString(map['hardware']),
    );
  }

  @override
  String toString() {
    return 'DeviceVersionPayload(project: $project, protocol: $protocol, '
        'firmware: $firmware, hardware: $hardware)';
  }
}
