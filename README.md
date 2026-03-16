# host4_flutter

`host4_flutter` 是一个用于承载 Flutter 模块、共享包、示例应用和原生宿主接入示例的 monorepo。

当前仓库只初始化最小可运行骨架，优先保证 `examples/host4_flutter_demo` 可作为 iOS / Android Flutter 示例应用运行。

## 目录结构

```text
host4_flutter/
├─ packages/
│  ├─ host4_flutter_core/
│  ├─ host4_flutter_utils/
│  ├─ host4_flutter_log/
│  ├─ host4_flutter_crypto/
│  ├─ host4_flutter_analytics/
│  ├─ host4_flutter_ui/
│  └─ host4_flutter_bridge/
├─ examples/
│  └─ host4_flutter_demo/
├─ hosts/
│  ├─ Host4FlutteriOSHostDemo/
│  └─ Host4FlutterAndroidHostDemo/
├─ tools/
├─ docs/
└─ README.md
```

## 说明

- `packages/`：Flutter / Dart 共享包
- `packages/host4_flutter_bridge/`：Flutter plugin 包
- `examples/host4_flutter_demo/`：最小示例应用
- `hosts/`：未来用于原生宿主接入示例
- `tools/`：脚本和工程化工具
- `docs/`：文档
