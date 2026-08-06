# iOS OTA 调用说明（BLE / MFi）

本文档整理当前 Flutter 项目中 iOS GMacro OTA 的调用方式、BLE 与 MFi 两种模式的原生分流、状态上报方式，以及测试 APP 中的验证入口。

涉及模块：

- `packages/host4_flutter_gmacro`
- `packages/host4_flutter_device_native`
- `packages/host4_flutter_ble`
- `packages/host4_flutter_mfi`
- `examples/host4_flutter_demo`

## 1. 总体调用链

iOS OTA 的上层调用入口是统一的，不需要业务层直接区分 BLE / MFi 调用不同 Dart API。

流程如下：

```text
BLE / MFi TransportSession
        ↓
Host4Gmacro.attach(transport)
        ↓
GmacroSession
        ↓
session.startOta(firmwareBytes)
        ↓
host4_flutter_device_native.startOta
        ↓
iOS Host4FlutterDeviceNativePlugin.startOta(...)
        ↓
根据 transportSession.source 分流：
  BLE → GMacroProtocolSession.startOTA(data:)
  MFi → GMacroProtocolSession.startMFIOTA(data:)
```

业务层推荐只依赖 `GmacroSession.startOta(...)` 和 `GmacroSession.events` / `GmacroSession.otaUpgradeEvents`。

## 2. Flutter 层调用方式

### 2.1 挂载 GMacro 协议

BLE 和 MFi 连接完成后，都会得到一个 `TransportSession`。进入 GMacro 页面后，先挂载协议：

```dart
final gmacro = Host4Gmacro();
final session = await gmacro.attach(transport);
```

当前测试 APP 入口：

- BLE：扫描 / 连接后进入 `GmacroSessionPage`
- MFi：检测 / 连接后进入 `GmacroSessionPage`

页面文件：

```text
examples/host4_flutter_demo/lib/pages/gmacro/gmacro_session_page.dart
```

### 2.2 启动 OTA

读取 `.bin` 固件为字节后调用：

```dart
await session.startOta(bytes);
```

其中：

- `bytes` 类型是 `Uint8List`
- BLE / MFi 都调用同一个 `session.startOta(bytes)`
- iOS 原生层会根据当前 transport 类型自动分流

测试 APP 当前内置固件选择：

```dart
GmacroBundledOtaFirmware gmacroBundledOtaFirmwareForTransportKind(
  TransportKind kind,
) {
  return switch (kind) {
    TransportKind.mfi => _mfiBundledOtaFirmware,
    TransportKind.ble || TransportKind.usb => _bleBundledOtaFirmware,
  };
}
```

当前内置文件：

```text
MFi: assets/ota/OTA_GDF-G910202_8520_V1.0_260715a.bin
BLE: assets/ota/OTA_GDF-G560637_46D4_V1.0_260510a.bin
```

## 3. iOS BLE OTA

### 3.1 挂载时配置 OTA 写入通道

BLE 挂载 GMacro 协议时，会配置两个 OTA 特征值：

```swift
let otaCommandChar = arguments["otaCommandCharacteristic"] as? String ?? "FF11"
let otaDataChar = arguments["otaDataCharacteristic"] as? String ?? "FF12"
```

含义：

- `FF11`：OTA command 通道
- `FF12`：OTA data 通道

当前 BLE 写入已使用带 completion 的 `writeValue(...)`：

```swift
bleSession.otaCommandWriter = { data, completion in
  try bleTransport?.writeValue(data, to: otaCommandChar, completion: completion)
}

bleSession.otaDataWriter = { data, completion in
  try bleTransport?.writeValue(data, to: otaDataChar, completion: completion)
}
```

这样可以保证最后一包固件数据写完后，再触发 `checkDfu` 校验流程，避免校验命令过早发送。

### 3.2 BLE OTA 原生分流

iOS 原生层统一入口：

```swift
private func startOta(protocolRecord: GMacroProtocolRecord, data: Data) {
  switch transportSessions[protocolRecord.transportSessionId]?.source {
  case .mfi:
    protocolRecord.session.startMFIOTA(data: data)
  default:
    protocolRecord.session.startOTA(data: data)
  }
}
```

BLE 会进入：

```swift
protocolRecord.session.startOTA(data: data)
```

### 3.3 BLE 成功日志判断

BLE OTA 最后设备返回类似：

```text
[Native] [BLE] [RX] 04 53 00 00
```

其中：

- `53 00`：`checkDfu`
- 最后的 `00`：设备端 OTA 校验成功

如果最后返回非 0，例如错误码 1，则原生 SDK 会产生失败事件：

```text
设备 OTA 校验失败，错误码 1
```

## 4. iOS MFi OTA

### 4.1 MFi 连接前协议参数

MFi 的 ExternalAccessory protocol string 不是固定值，当前设计应由 Flutter API 参数或项目配置传入，不应写死为 `com.OSYN`。

典型流程：

```dart
final mfi = Host4Mfi();
await mfi.start();
await mfi.updateProtocol(protocolString);
final transport = await mfi.connect();
```

其中 `protocolString` 由接入方按实际 MFi 设备配置传入。

### 4.2 MFi 挂载时配置 OTA 写入通道

MFi 挂载 GMacro 协议时，会创建专用的 `GMacroProtocolSession`，并配置 MFi OTA command/data 写入：

```swift
let mfiSession = GMacroProtocolSession(
  sessionId: sessionId,
  transport: byteTransport
)

mfiSession.otaCommandWriter = { data, completion in
  try mfiTransport.writeValue(
    data,
    to: MFiTransportSession.otaCommandCharacteristic,
    completion: completion
  )
}

mfiSession.otaDataWriter = { data, completion in
  try mfiTransport.writeValue(
    data,
    to: MFiTransportSession.otaDataCharacteristic,
    completion: completion
  )
}
```

### 4.3 MFi OTA 原生分流

MFi 会进入：

```swift
protocolRecord.session.startMFIOTA(data: data)
```

也就是说，Flutter 层仍然调用：

```dart
await session.startOta(bytes);
```

但 iOS 原生会自动使用 MFi 专用 OTA 流程。

## 5. 状态上报方式

当前有两类状态流可用。

### 5.1 GMacro 协议事件流：`session.events`

推荐页面层必须监听：

```dart
final sub = session.events.listen((event) {
  switch (event) {
    case ProtocolReady():
      // 协议 ready

    case ProtocolBusy(reason: final reason, payload: final payload):
      // OTA progress / success 或其他协议 busy 事件

    case ProtocolError(failure: final failure):
      // OTA 或协议失败
  }
});
```

iOS 原生 OTA 事件映射为：

```text
progress:
  type: busy
  reason: progress
  payload:
    event: progress
    progress: 0.0 ~ 1.0

success:
  type: busy
  reason: success
  payload:
    event: success

failure:
  type: error
  failure:
    code: gmacro-failure
    message: 失败原因
```

页面处理建议：

```dart
if (event is ProtocolBusy) {
  switch (event.payload['event']) {
    case 'progress':
      final progress = event.payload['progress'] as num;
      final percent = progress.toDouble();
      break;

    case 'success':
      // OTA 成功
      break;
  }
}

if (event is ProtocolError) {
  // OTA 失败或协议失败
}
```

注意：当前成功事件也是 `ProtocolBusy(reason: 'success')`，页面不要在收到 `success` 后继续把 UI 状态改成 busy。

### 5.2 Native OTA 事件流：`session.otaUpgradeEvents`

`GmacroSession` 也暴露了原生 OTA 事件流：

```dart
final otaSub = session.otaUpgradeEvents.listen((event) {
  switch (event.type) {
    case NativeOtaUpgradeEventType.progress:
      final percent = event.percent;
      final progress = event.progress;
      final total = event.total;
      break;

    case NativeOtaUpgradeEventType.success:
      // OTA 成功
      break;

    case NativeOtaUpgradeEventType.failed:
      final code = event.code;
      break;
  }
});
```

事件字段：

```dart
class NativeOtaUpgradeEvent {
  final NativeOtaUpgradeEventType type; // progress / success / failed
  final int progress;
  final int total;
  final double percent;
  final int? code;
}
```

当前测试 APP 同时监听了：

- `session.events`
- `session.otaUpgradeEvents`

其中 OTA 成功展示主要依赖 GMacro 协议事件的 `payload.event == success`。

## 6. 测试 APP 验证方式

### 6.1 BLE OTA

1. 打开测试 APP。
2. 进入 `GMacro 调试`。
3. 选择 `BLE 连接`。
4. 扫描并连接 BLE 设备。
5. 进入 `GmacroSessionPage`。
6. 点击 `OTA 测试`。
7. 选择 `已有文件`，会使用 BLE 内置固件：

```text
assets/ota/OTA_GDF-G560637_46D4_V1.0_260510a.bin
```

8. 观察事件日志和顶部状态栏：

```text
OTA 升级中 xx.x%
OTA 升级成功
```

### 6.2 MFi OTA

1. 确认 MFi protocol string 已通过参数传入。
2. 打开测试 APP。
3. 进入 `GMacro 调试`。
4. 选择 `MFi 连接`，或在首页检测到 MFi 设备后自动进入会话页。
5. 进入 `GmacroSessionPage`。
6. 点击 `OTA 测试`。
7. 选择 `已有文件`，会使用 MFi 内置固件：

```text
assets/ota/OTA_GDF-G910202_8520_V1.0_260715a.bin
```

8. 观察事件日志和顶部状态栏。

## 7. 推荐接入代码模板

```dart
Future<void> runOta({
  required TransportSession transport,
  required Uint8List firmwareBytes,
}) async {
  final gmacro = Host4Gmacro();
  final session = await gmacro.attach(transport);

  final protocolSub = session.events.listen((event) {
    switch (event) {
      case ProtocolReady():
        print('GMacro ready');

      case ProtocolBusy(reason: final reason, payload: final payload):
        if (payload['event'] == 'progress') {
          final progress = (payload['progress'] as num?)?.toDouble() ?? 0;
          print('OTA progress: ${(progress * 100).toStringAsFixed(1)}%');
        } else if (payload['event'] == 'success') {
          print('OTA success');
        } else {
          print('GMacro busy: $reason');
        }

      case ProtocolError(failure: final failure):
        print('OTA/protocol failed: ${failure.code} ${failure.message}');
    }
  });

  final otaSub = session.otaUpgradeEvents.listen((event) {
    switch (event.type) {
      case NativeOtaUpgradeEventType.progress:
        print('Native OTA progress: ${event.percent}');
      case NativeOtaUpgradeEventType.success:
        print('Native OTA success');
      case NativeOtaUpgradeEventType.failed:
        print('Native OTA failed: ${event.code}');
    }
  });

  try {
    await session.startOta(firmwareBytes);
  } finally {
    await protocolSub.cancel();
    await otaSub.cancel();
  }
}
```

实际业务中不要在 `startOta(...)` 返回后立刻取消监听；`startOta(...)` 只表示 OTA 已发起，最终成功/失败要等事件流回调。

## 8. 常见问题

### 8.1 `startOta(...)` 返回了，是否代表升级成功？

不是。`startOta(...)` 返回只代表 Flutter 已把固件数据交给原生层并成功发起流程。最终结果必须看事件：

- `ProtocolBusy(payload.event == success)`
- 或 `NativeOtaUpgradeEventType.success`
- 失败看 `ProtocolError` 或 `NativeOtaUpgradeEventType.failed`

### 8.2 BLE 到 100% 后失败，如何判断？

如果日志最后是：

```text
[BLE] [RX] 04 53 00 00
```

表示设备校验成功。

如果日志提示：

```text
设备 OTA 校验失败，错误码 1
```

表示固件已发完，但设备端最终校验拒绝。优先检查：

- 固件是否匹配当前设备型号 / 硬件版本。
- 是否使用了正确的 BLE 固件，而不是 MFi 固件。
- 设备端 bootloader / signature / version 规则是否允许该包。

### 8.3 为什么成功事件会显示 Busy？

当前 iOS 原生层为了复用 `ProtocolEvent`，将 OTA 成功映射为：

```text
type: busy
reason: success
payload.event: success
```

因此 UI 处理时要特殊判断 `reason == success` 或 `payload.event == success`，不要把它当作普通 busy 状态。

### 8.4 MFi protocol string 是否固定？

不是。MFi ExternalAccessory protocol string 应作为参数或项目配置传入，不应写死。当前接入时通过：

```dart
await mfi.updateProtocol(protocolString);
```

配置实际协议值。

