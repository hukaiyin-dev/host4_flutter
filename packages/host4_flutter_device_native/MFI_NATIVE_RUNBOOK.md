# OTA 调用与事件监听

## 调用 OTA

Flutter 侧 BLE 和 MFi 都统一调用 `startOta`：

```dart
import 'dart:typed_data';

import 'package:host4_flutter_device_native/host4_flutter_device_native.dart';

final native = Host4FlutterDeviceNative();

Future<void> startOta({
  required String protocolSessionId,
  required Uint8List firmwareData,
}) {
  return native.startOta(
    protocolSessionId: protocolSessionId,
    firmwareData: firmwareData,
  );
}
```

说明：

- `protocolSessionId`：`attachGmacroProtocol` 成功后返回的协议 session id
- `firmwareData`：固件 bin 文件字节数据
- OTA 调用时不需要额外传 `ble` 或 `mfi` 类型
- iOS 原生侧会根据 `protocolSessionId` 对应的 transport 自动区分 BLE OTA 或 MFi OTA

区分方式：

```text
BLE 连接
  -> attachGmacroProtocol(bleTransportSessionId)
  -> 得到 BLE 对应的 protocolSessionId
  -> startOta(protocolSessionId, firmwareData)
  -> iOS 原生走 BLE OTA

MFi 连接
  -> attachGmacroProtocol(mfiTransportSessionId)
  -> 得到 MFi 对应的 protocolSessionId
  -> startOta(protocolSessionId, firmwareData)
  -> iOS 原生走 MFi OTA
```

## 监听 OTA

统一监听 `otaUpgradeEvents(protocolSessionId)`：

```dart
final otaSub = native.otaUpgradeEvents(protocolSessionId).listen((event) {
  switch (event.type) {
    case NativeOtaUpgradeEventType.progress:
      final progress = event.percent; // 0.0 - 1.0
      break;

    case NativeOtaUpgradeEventType.success:
      break;

    case NativeOtaUpgradeEventType.failed:
      final code = event.code;
      break;
  }
});
```

## 事件参数

OTA 事件包含三个核心参数：

```dart
class NativeOtaUpgradeEvent {
  final NativeOtaUpgradeEventType type;
  final double percent;
  final int? code;
}
```

`type`：

- `progress`：升级进度
- `success`：升级成功
- `failed`：升级失败

`percent`：

- 进度值，范围 `0.0 - 1.0`
- 页面显示百分比时使用 `percent * 100`

`code`：

- `100`：进度事件
- `0`：升级成功
- `1`：固件校验或 OTA 准备阶段失败
- `2`：设备请求单次固件数据失败
- `3`：固件传输、烧录或最终校验失败
