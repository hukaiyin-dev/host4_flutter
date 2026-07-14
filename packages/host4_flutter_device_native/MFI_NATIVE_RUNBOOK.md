# host4_flutter_device_native MFi 原生运行说明

`host4_flutter_device_native` 承担 MFi 的 iOS 原生桥接工作。Flutter 层通过 MethodChannel 调用本包，本包再接入 `MFiKit` 和 `GMacroProtocolSDK`。

## 主要职责

- 通过 `MFiKit.MFiTransportSession` 建立 iAP2 transport。
- 把 MFi transport 包装成 `AnyByteStreamTransport`。
- 注册到 `NativeAdapterRuntime`，让 GMacro 协议层可以复用统一 transport。
- 在 `attachGmacroProtocol` 时创建 `GMacroProtocolSession`。
- 在 OTA 时按 transport 类型分流到 BLE OTA 或 MFi OTA。

## iOS 必要配置

宿主 App 必须在 `Info.plist` 声明正式设备的 ExternalAccessory protocol string：

```xml
<key>UISupportedExternalAccessoryProtocols</key>
<array>
  <string>com.OSYN</string>
</array>
```

`com.OSYN` 只是 demo 默认值。客户正式设备如果使用其他 protocol，需要替换为真实值，并确保 Dart 侧传入同一个字符串。

## MethodChannel 入口

MFi 相关方法：

- `connectMfi`
- `isMfiAccessoryConnected`
- `mfiAccessoryEvents`
- `disconnectTransport`
- `attachGmacroProtocol`
- `startOta`
- `invokeGmacroMethod`
- `closeProtocol`

### connectMfi

参数：

```dart
{
  'protocolString': '<ExternalAccessory protocol>',
  'options': {...}
}
```

iOS 执行内容：

1. 创建 `MFiTransportSession(sessionId:protocolString:)`。
2. 用 `send` 和 `onReceive` 包装为 `AnyByteStreamTransport`。
3. 监听 `MFiTransportState`，转换为 Flutter transport event。
4. 注册 transport。
5. 调用 `mfiSession.connect()`。

返回值是 transport session id，格式类似：

```text
mfi-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### isMfiAccessoryConnected

通过 `EAAccessoryManager.shared().connectedAccessories` 判断当前是否有 accessory 包含指定 protocol string。

该方法只表示系统当前能看到匹配设备，不等同于 GMacro 协议已经 ready。

### mfiAccessoryEvents

EventChannel：

```text
host4_flutter_device_native/mfi_accessory_events
```

订阅参数：

```dart
{
  'protocolString': '<ExternalAccessory protocol>'
}
```

iOS 原生处理：

1. 调用 `EAAccessoryManager.shared().registerForLocalNotifications()`。
2. 监听 `EAAccessoryDidConnect` 和 `EAAccessoryDidDisconnect`。
3. 按 `protocolString` 过滤 accessory。
4. 订阅时立即扫描当前已连接 accessories，并先推送已有连接状态。
5. 后续插入/拔出时继续推送事件。

事件格式：

```dart
{
  'type': 'connected' | 'disconnected' | 'failed',
  'protocolString': '<matched protocol>',
  'name': '<accessory name>',
  'metadata': {
    'manufacturer': '...',
    'modelNumber': '...',
    'serialNumber': '...',
    'firmwareRevision': '...',
    'hardwareRevision': '...',
    'protocolStrings': [...]
  }
}
```

该事件流只表达系统层 accessory 插拔，不会自动创建 `MFiTransportSession`。真正通信仍由 `connectMfi` 负责。

## GMacro attach 流程

`attachGmacroProtocol` 会根据 transport source 分支处理。

### BLE 分支

BLE 使用 `NativeAdapterRuntime.shared.attachGMacroProtocol(...)`，并配置普通 OTA writer：

- `otaCommandWriter` 写入 BLE OTA command characteristic
- `otaDataWriter` 写入 BLE OTA data characteristic

### MFi 分支

MFi 创建：

```swift
GMacroProtocolSession(sessionId: sessionId, transport: byteTransport)
```

并配置：

- `onEvent`：普通 GMacro protocol event
- `mfiOTAEvent`：MFi 专用 OTA progress/success/failure
- `otaCommandWriter`：写入 `MFiTransportSession.otaCommandCharacteristic`
- `otaDataWriter`：写入 `MFiTransportSession.otaDataCharacteristic`

`mfiOTAEvent` 会被转换成 Flutter protocol event，使现有页面可以继续用同一套事件显示 OTA 状态。

## OTA 分流规则

Flutter 层统一调用：

```dart
GmacroSession.startOta(firmwareData)
```

iOS 原生根据 protocol session 对应的 transport source 分流：

- MFi：`GMacroProtocolSession.startMFIOTA(data:)`
- BLE：`GMacroProtocolSession.startOTA(data:)`

这点很重要。MFi 不能直接复用 BLE 的普通 OTA 状态机，否则可能出现：

```text
Protocol: Error gmacro-failure - OTA 通道未配置
```

## 事件映射

### Transport event

`MFiTransportState` 映射为 Flutter transport event：

- `connecting` -> `TransportConnecting`
- `connected` -> `TransportConnected`
- `ready` -> `TransportReady`
- `disconnected` -> `TransportDisconnected`
- `error` -> `TransportError`

### MFi OTA event

`MFIOTAEvent` 映射为 Flutter protocol event：

- `progress(CGFloat)` -> `ProtocolBusy(reason: 'progress')`
- `success` -> `ProtocolBusy(reason: 'success')`
- `failure(String)` -> `ProtocolError`

测试 App 的详情页会读取这些事件来更新顶部 OTA 状态。

## 测试 App 验证路径

测试入口：

```text
examples/host4_flutter_demo
```

MFi 流程：

1. 进入 GMacro 调试页。
2. 点击「MFi 连接」。
3. 连接成功后进入 `GmacroSessionPage`。
4. 点击「OTA 测试」。
5. 选择「已有文件」或选择本地 bin。

demo 当前内置固件：

```text
assets/ota/OTA_GDF-G910202_F542_V1.0_260708c.bin
```

## 验证命令

建议在改动 MFi 原生桥接后至少执行：

```sh
flutter analyze lib test
```

在 demo 里执行：

```sh
flutter analyze lib/pages/gmacro/gmacro_session_page.dart
flutter test test/widget_test.dart
flutter build ios --debug --no-codesign
```

`flutter build ios --debug --no-codesign` 可以验证 Swift 代码与当前 `MFiKit`、`GMacroProtocolSDK` 的 API 是否匹配，但最终 MFi 连接和 OTA 仍需要 iOS 真机与正式设备验证。

## 排查清单

### 连接失败

- 真机是否连接了 MFi 设备。
- `Info.plist` 是否声明正确 protocol string。
- Flutter 传入的 protocol string 是否和设备一致。
- 设备是否完成 iAP2 握手。

### attach 成功但 OTA 失败

- 确认 `startOta` 是否进入 MFi 分支。
- 确认是否调用 `startMFIOTA(data:)`。
- 确认 `mfiOTAEvent` 是否桥接。
- 查看 Flutter 页面 Native log。

### API 可用但 OTA 没进度

- 关注 `MFIOTAEvent.progress` 是否产生。
- 确认页面订阅的是 protocol event。
- 检查固件文件是否为空，bin 是否匹配设备。
