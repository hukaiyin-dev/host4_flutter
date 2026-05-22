# host4_flutter 项目概览

本文档面向团队成员，介绍项目的包结构与各包职责。

---

## 项目定位

`host4_flutter` 是公司内部的 Flutter 基础能力 monorepo，承载可复用的 UI 组件、主题系统、设备通信桥接层和业务模块。使用 [Melos](https://melos.invertase.dev/) 管理多包工作区。

---

## 包一览

项目下所有包位于 `packages/` 目录，按职责分为：

```
基础设施层
  host4_flutter_core
  host4_flutter_utils
  host4_flutter_log
  host4_flutter_crypto
  host4_flutter_analytics

UI
  host4_flutter_ui

设备通信（抽象 → 桥接 → 具体传输）
  host4_flutter_transport
  host4_flutter_protocol
  host4_flutter_device_native
  host4_flutter_bridge
  host4_flutter_ble
  host4_flutter_mfi
  host4_flutter_usb
  host4_flutter_gmacro

业务模块
  host4_flutter_module_onboarding
```

---

## 基础设施层

### host4_flutter_core

项目的基础契约包，纯 Dart（无 Flutter 依赖）。

定义了整个 SDK 通用的抽象和协议：
- 异常类型（`Host4Exception`）
- 日志级别与日志接口（`Host4LogLevel` / `Host4LogSink`）
- 模块抽象（`Host4Module`）
- 运行时环境描述（`Host4Environment`）

其他包可依赖此包获取共享类型，而不引入额外依赖。

---

### host4_flutter_utils

通用工具包，提供数据读取和配置解析能力：
- JSON 读取工具（`Host4Json`）
- 配置引用解析（`Host4ReferenceResolver`，用于解析 JSON 配置中 `$ref` 风格的引用）

---

### host4_flutter_log

日志系统实现包。基于 `host4_flutter_core` 的日志抽象，提供：
- `Host4Logger`：主日志类，支持多 sink 输出
- `Host4LoggerConfig`：日志配置（级别过滤、格式等）
- 文件日志支持（依赖 `path_provider`）

---

### host4_flutter_crypto

加密与编码工具包，纯 Dart：
- Base64 编解码（`Host4Codec`）
- SHA 哈希（`Host4Hash`）
- HMAC 签名（`Host4Hmac`）

---

### host4_flutter_analytics

事件采集包，纯 Dart，支持多 sink 输出：
- `Host4Event`：通用事件模型
- `Host4AnalyticsClient`：事件上报入口，支持注册多个 sink
- `Host4AnalyticsSink`：接口，业务方实现后注入
- 内置 `LoggerAnalyticsSink`，将事件打印到日志（用于调试）

---

## UI 层

### host4_flutter_ui

通用 UI 组件库 + 运行时主题系统。

主题系统基于 JSON 驱动，支持运行时切换主题、Light/Dark mode：
- `Host4ThemeManager`：主题全局管理，负责加载和切换
- `Host4ThemeScope`：InheritedWidget，向子树注入当前主题
- `Host4RuntimeTheme`：运行时主题对象，封装 token 查询接口
- `Host4ThemeLoader`：从 assets 加载 JSON 主题包

设计 token 采用三层结构：`primitive → semantic → component`，从 Figma 导出后由工具链转换为包内 JSON 文件。

内置通用组件（均消费当前主题 token）：
`Host4Button` / `Host4Card` / `Host4Text` / `Host4TextField` /
`Host4NavigationBar` / `Host4TabBar` / `Host4SearchBar` /
`Host4ListCell` / `Host4SectionHeader` / `Host4PageScaffold` / `Host4Background`

---

## 设备通信层

通信层按职责分层，依赖方向从抽象到具体：

```
host4_flutter_transport   （传输抽象）
       ↑
host4_flutter_protocol    （协议抽象）
       ↑
host4_flutter_device_native  （原生桥接插件）
       ↑
  ble / mfi / usb / gmacro   （具体传输/协议实现）
```

---

### host4_flutter_transport

传输层抽象包，纯接口，无具体实现：
- `DeviceDescriptor`：设备描述（标识符、名称、信号强度等）
- `DeviceDiscovery`：设备扫描接口
- `TransportSession`：与单台设备的传输会话接口
- `TransportEvent` / `TransportFailure`：事件与错误类型
- `TransportKind`：传输类型枚举（BLE / MFi / USB）

---

### host4_flutter_protocol

协议层抽象包，在传输层之上定义协议会话接口：
- `ProtocolSession`：协议级别的会话，封装指令收发语义
- `ProtocolEvent` / `ProtocolFailure`：协议事件与错误

---

### host4_flutter_device_native

Flutter plugin，是 Flutter 侧与原生设备 SDK 的桥接核心：
- 通过 Method Channel 和 EventChannel 与 iOS（Swift）/ Android（Kotlin）通信
- iOS 侧集成 BluetoothKit、MFiKit、GMacroProtocolSDK
- `QueuedEventStreamHandler`：事件流缓冲机制，防止 Dart 未监听时丢事件
- 上层的 `host4_flutter_ble` / `host4_flutter_gmacro` 等包均依赖此包

---

### host4_flutter_bridge

通用原生桥接 plugin，提供与 `host4_flutter_device_native` 并列的通用 Method Channel 基础设施。目前职责边界仍在梳理中。

---

### host4_flutter_ble

BLE 传输实现包，封装 BLE 扫描和连接逻辑：
- `Host4Ble`：BLE 传输入口，实现 `DeviceDiscovery` 和 `TransportSession` 接口
- 依赖 `host4_flutter_device_native` 获取底层事件流

---

### host4_flutter_mfi

MFi（苹果 MFi 配件协议）传输预留包，结构与 BLE 对称，待后续实现。

---

### host4_flutter_usb

USB 传输预留包，结构与 BLE 对称，待后续实现。

---

### host4_flutter_gmacro

GMacro 协议实现包（公司内部设备通信协议）：
- `Host4Gmacro`：GMacro 协议入口
- `GmacroSession`：实现 `ProtocolSession`，封装 GMacro 指令的编解码与收发
- 依赖 `host4_flutter_device_native`（传输）和 `host4_flutter_protocol`（接口）

---

## 业务模块层

### host4_flutter_module_onboarding

通用 Onboarding 流程模块，可嵌入任意 Flutter 应用：
- `OnboardingPageConfig`：数据驱动的页面配置（标题、图片、描述、按钮文案）
- `OnboardingFlow`：多页流程控制组件
- `OnboardingPageView` / `OnboardingPageContent`：页面渲染
- `OnboardingStore`：基于 `shared_preferences` 记录是否已看过引导

---

## 其他目录

| 目录 | 说明 |
|------|------|
| `examples/` | 示例应用 `host4_flutter_demo`，集成所有基础包，可用于本地验证 |
| `hosts/` | iOS / Android 宿主接入示例，演示如何将 Flutter 作为模块嵌入原生 App |
| `tools/` | Figma ↔ JSON 变量转换工具（`host4_figma_variables_to_json` / `host4_json_to_figma_variables`） |
