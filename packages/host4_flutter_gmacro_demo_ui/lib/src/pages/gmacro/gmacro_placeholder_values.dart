import 'package:host4_flutter_gmacro/host4_flutter_gmacro.dart';

/// Demo 专用占位配置，集中管理示例设备的蓝牙参数。
/// 对应 iOS 侧的 PlaceholderValues.swift，不属于 SDK 本身。
abstract final class GmacroPlaceholderValues {
  static const String service = 'FF00';
  static const String mfiProtocolString = 'com.HOST4';

  static const config = GmacroConfig(service: service);

  static const List<String> deviceNames = ['Mobapad-ML35'];
  static const bool exactDeviceNameMatch = false;
}
