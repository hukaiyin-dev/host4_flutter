# AI 语音 SDK 文档

## 概述

`host4_flutter_aivoice` 提供 AI 语音对话功能，所有引擎逻辑和 UI 由 Native 层处理，Flutter 侧只需一行代码即可接入。

**架构：**
- **Flutter SDK** — 只提供 API 入口，无线程/UI 逻辑
- **iOS Native** — 火山引擎 RTC + 智能体 + 悬浮窗/聊天 UI + 字幕

---

## 接入步骤

### 1. 添加依赖

```yaml
# pubspec.yaml
dependencies:
  host4_flutter_aivoice:
    path: ../host4_flutter/packages/host4_flutter_aivoice
```

### 2. iOS 配置

`ios/Podfile` 中已自动集成，无需手动配置。如需手动安装：

```bash
cd ios && pod install
```

---

## API 参考

### `showAI()`

启动 AI 语音，显示悬浮球。

```dart
static Future<bool> showAI({
  required String boostingTableID,
  String? language,
});
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `boostingTableID` | `String` | ✅ | 智能体配置 ID |
| `language` | `String?` | ❌ | 语言代码（`zh`/`en`/`ja`等），不传使用系统语言 |

**返回值：** `true` 成功，`false` 失败

**示例：**
```dart
// 中文
await Host4FlutterAiVoice.showAI(boostingTableID: 'GameMacro');

// 英文
await Host4FlutterAiVoice.showAI(boostingTableID: 'GameMacro', language: 'en');
```

---

### `hideAI()`

关闭 AI 语音，销毁引擎和 UI。

```dart
static Future<bool> hideAI();
```

**返回值：** `true` 成功

**示例：**
```dart
await Host4FlutterAiVoice.hideAI();
```

---

### `setVipHandler()`

设置 VIP 检查/扣费回调（**必须在 `showAI` 之前调用**）。

```dart
static void setVipHandler(
  Future<Map<String, dynamic>> Function(Map<String, dynamic> call) handler,
);
```

**VIP 双向通信机制：**

```
无 setVipHandler（测试）:
  Plugin.registerVip 未调用 → vipMethodChannel = nil
  → getVipUseInfo 检测到 nil → 直接 switchAudioCapture(true) ✅
  → 默认放行，适合开发测试

有 setVipHandler（生产）:
  setVipHandler → invokeMethod('registerVip') → Plugin 设置 vipMethodChannel
  → getVipUseInfo → invokeMethod("vipAction") → Flutter handler 返回结果
  → allowed=true 放行 / allowed=false 显示非VIP状态
```

**回调参数 `call`：**

| Key | 类型 | 说明 |
|-----|------|------|
| `type` | `String` | `"check"`（进房权限检查）/ `"deduction"`（扣费请求） |
| `chatbotId` | `String` | 智能体 ID |

**回调返回值：**

| Key | 类型 | 说明 |
|-----|------|------|
| `allowed` | `bool` | 是否允许继续 |

**示例：**
```dart
Host4FlutterAiVoice.setVipHandler((call) async {
  final type = call['type'] as String;

  if (type == 'check') {
    // 检查用户 VIP 状态
    final isVip = await MyVipService.check();
    return {'allowed': isVip};
  }

  if (type == 'deduction') {
    // 上报扣费
    final success = await MyVipService.reportDeduction();
    return {'allowed': success};
  }

  return {'allowed': false};
});

// 然后再启动
await Host4FlutterAiVoice.showAI(boostingTableID: 'xxx');
```

> **注意：** 如果不设置 `setVipHandler`，SDK 会默认放行所有权限。

---

### `events`

监听 AI 语音事件流。

```dart
static Stream<Map<String, dynamic>> get events;
```

**事件格式：**

```dart
{"event": "subtitle", "text": "你好，有什么可以帮你的？"}
{"event": "statusChanged", "state": "connected"}
{"event": "voiceActivity", "isSpeaking": true}
```

**示例：**
```dart
Host4FlutterAiVoice.events.listen((event) {
  print('收到事件: ${event['event']}');

  switch (event['event']) {
    case 'subtitle':
      print('字幕: ${event['text']}');
    case 'statusChanged':
      print('状态: ${event['state']}');
    case 'voiceActivity':
      print('说话中: ${event['isSpeaking']}');
  }
});
```

---

## 完整示例

```dart
import 'package:host4_flutter_aivoice/host4_flutter_aivoice.dart';

class AiVoiceDemo extends StatefulWidget {
  @override
  State<AiVoiceDemo> createState() => _AiVoiceDemoState();
}

class _AiVoiceDemoState extends State<AiVoiceDemo> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    // 1. 设置 VIP 回调
    Host4FlutterAiVoice.setVipHandler((call) async {
      return {'allowed': true}; // 示例：直接放行
    });
  }

  Future<void> _start() async {
    // 2. 启动（传入语言）
    final ok = await Host4FlutterAiVoice.showAI(
      boostingTableID: 'GameMacro',
      language: 'zh',
    );
    if (!ok) return;

    // 3. 监听事件
    _sub = Host4FlutterAiVoice.events.listen((event) {
      debugPrint('📡 ${event['event']}');
    });
  }

  Future<void> _stop() async {
    _sub?.cancel();
    await Host4FlutterAiVoice.hideAI();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _start,
          child: Text('开启 AI 语音'),
        ),
      ),
    );
  }
}
```

---

## 工作流程

```
showAI()
  → Plugin 传递 boostingTableID + language 到 Native
  → AiViewManager 显示悬浮球
  → 用户点击悬浮球 → 展开聊天窗
  → AiVoiceManager.buildRTCEngine() 创建火山引擎 RTC
  → joinRoom() 加入房间
  → onRoomStateChanged(state=0) → startAgent() HTTP 通知智能体加入
  → getVipUseInfo(0) 权限检查：
      - 未设置 setVipHandler：直接放行，开麦
      - 已设置 setVipHandler：invokeMethod("vipAction") → Flutter 返回 allowed
  → 开麦 → 开始对话
  → 用户说话 → VAD 检测(isSpeaking) → 火山返回字幕(subv)
  → SubtitleTextAssembler 拼接/去重 → ChatBubbleView 气泡显示
  → 检测到完整句子(definite+paragraph) → getVipUseInfo(1) 扣费
```

**VIP 权限检查时机：**

| type | 时机 | 说明 |
|------|------|------|
| `0` (check) | 智能体加入成功后 | 判断用户是否可以开麦对话 |
| `1` (deduction) | 收到机器人完整句子后 | 上报扣费，检查剩余额度 |

---

## 注意事项

1. `setVipHandler` 必须在 `showAI` 之前调用
2. `language` 参数只在 `showAI` 时传入，后续切换语言需重新调用 `hideAI` → `showAI`
3. 悬浮窗和聊天 UI 由 Native 层管理，位于 Flutter 视图之上
4. 重复调用 `showAI` 不会重复创建，需先 `hideAI` 再重启
