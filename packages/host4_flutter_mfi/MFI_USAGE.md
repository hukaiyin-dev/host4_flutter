# host4_flutter_mfi MFi 运行说明

`host4_flutter_mfi` 提供 Flutter 侧的 MFi transport 封装。它负责启动 MFi 流程、设置 ExternalAccessory protocol、连接设备，并把连接结果包装成 `TransportSession`，供 `host4_flutter_gmacro` 继续挂载协议和执行接口测试。

## 适用范围

- 仅 iOS 真机可用。
- Android 不支持 MFi，这是 Apple 专有能力。
- 模拟器通常无法验证真实 ExternalAccessory 连接。

## 依赖关系

调用链如下：

1. App 引入 `host4_flutter_mfi`。
2. `Host4Mfi.connect()` 调用 `host4_flutter_device_native`。
3. iOS 原生使用 `MFiKit.MFiTransportSession` 建立 iAP2 通道。
4. 连接成功后返回 `Host4MfiTransportSession`。
5. GMacro 场景继续调用 `Host4Gmacro.attach(transport)`。

## protocolString 配置

MFi 的 ExternalAccessory protocol string 不是 SDK 固定值，必须按客户正式设备配置。

示例 demo 当前把默认值放在：

```dart
GmacroPlaceholderValues.mfiProtocolString
```

如果客户设备不是 `com.OSYN`，需要同时修改两处：

- Flutter 运行参数：传给 `Host4Mfi.updateProtocol()` 或 `Host4Mfi.connect(protocolString: ...)`
- iOS `Info.plist`：`UISupportedExternalAccessoryProtocols`

iOS 系统会先根据 `Info.plist` 判断 App 是否声明支持该 accessory protocol。只改 Dart 参数而不改 `Info.plist`，可能导致系统层无法建立会话。

## 基本连接流程

推荐三步流程：

```dart
final mfi = Host4Mfi();

await mfi.start();
await mfi.updateProtocol(protocolString);
final transport = await mfi.connect(
  options: const <String, Object?>{'protocolType': 'gmacro'},
);
```

连接成功后，`transport` 可以直接传给 GMacro：

```dart
final gmacro = Host4Gmacro();
final session = await gmacro.attach(transport);
```

## 常用 API

### start

```dart
await mfi.start();
```

当前为轻量启动入口，保留给后续监听、权限或初始化扩展。

### updateProtocol

```dart
await mfi.updateProtocol(protocolString);
```

保存本次连接使用的 ExternalAccessory protocol string。传空字符串会抛出参数错误。

### isAccessoryConnected

```dart
final connected = await mfi.isAccessoryConnected();
```

检查当前 iOS 已连接 accessories 中是否存在匹配 protocol string 的设备。调用前需要先 `updateProtocol()`，也可以直接传入 `protocolString`。

### connect

```dart
final transport = await mfi.connect();
```

创建 MFi transport session。返回的 `Host4MfiTransportSession` 实现了通用 `TransportSession` 接口。

### disconnect

```dart
await mfi.disconnect();
```

断开当前 active MFi session。

### events

```dart
mfi.events.listen((event) {
  // TransportConnecting / TransportConnected / TransportReady / ...
});
```

注意：当前 `events` 只转发 active session 的事件。连接前监听会得到空流。

### accessoryEvents

```dart
await mfi.updateProtocol(protocolString);

mfi.accessoryEvents.listen((event) {
  // MfiAccessoryEventType.connected / disconnected / failed
});
```

`accessoryEvents` 用于监听 iOS 系统层 MFi accessory 插入/拔出。它不代表 GMacro 协议已经 ready，只表示 iOS 当前看到了匹配 protocol string 的 ExternalAccessory。

建议用法：

- 页面初始化时调用 `updateProtocol()`。
- 订阅 `accessoryEvents`，用于更新“已检测到设备”等 UI 状态。
- 用户点击连接时，仍调用 `connect()` 建立真正的数据 session。

这和 `events` 的语义不同：

- `accessoryEvents`：未连接 session 前的物理插拔状态。
- `events`：`connect()` 后的 transport session 状态。

## OTA 说明

MFi 的 OTA 不直接在 `host4_flutter_mfi` 包里执行。正确路径是：

1. `Host4Mfi.connect()` 返回 MFi transport。
2. `Host4Gmacro.attach(transport)` 创建 GMacro protocol session。
3. 调用 `GmacroSession.startOta(firmwareData)`。
4. iOS 原生根据 transport 类型分流：
   - MFi 调用 `GMacroProtocolSession.startMFIOTA(data:)`
   - BLE 调用 `GMacroProtocolSession.startOTA(data:)`

因此，测试 App 中从 MFi 入口进入详情页后，点击「OTA 测试」会走 MFi 专用 OTA 状态机。

## 常见问题

### 点击 MFi 连接失败

优先检查：

- 是否在 iOS 真机运行。
- 设备是否已完成 iAP2 连接。
- Dart 传入的 protocol string 是否和设备一致。
- `Info.plist` 的 `UISupportedExternalAccessoryProtocols` 是否声明了同一个值。

### OTA 报“OTA 通道未配置”

这通常表示 MFi 误走了普通 BLE OTA 路径，或者原生未按 transport 类型分流。当前实现中 MFi 已分流到 `startMFIOTA(data:)`，如果仍出现该错误，需要确认 App 使用的是最新的 `host4_flutter_device_native`。

### 连接后 API 测试可用但 OTA 无进度

检查原生 `mfiOTAEvent` 是否被桥接到 Flutter protocol event，以及页面是否订阅了 protocol events。测试 App 已兼容 MFi OTA 的 progress/success/failure 事件。
