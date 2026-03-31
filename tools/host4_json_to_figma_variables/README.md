# Host4 json to Figma variables

## 核心功能
自动化将 Flutter 项目中的 `tokens.json` 转换为 Figma Variables，并建立严格的引用链约束（Primitive -> Semantic -> Component）。

## 安装步骤
- 在 Figma 桌面版中，点击顶部菜单：**Plugins > Development > Import plugin from manifest...**。
- 选择本项目目录下的 `manifest.json` 文件。
- 插件将出现在你的本地开发插件列表中。

## 使用方法
- 在 Figma 文件中运行 **Host4 json to Figma variables**。
- 弹出的窗口提供了一个拖拽区域。
- 将项目中的 `tokens.json` 文件（通常位于 `assets/themes/default/`）拖入窗口。
- 插件会自动解析并同步以下三个 Collections：
  - **Primitive**: 基础原子值（颜色、数值）。
  - **Semantic**: 语义化定义，链接至 Primitive。
  - **Component**: 组件级定义，链接至 Semantic。

## 注意事项
- 插件会自动处理 Light/Dark 模式（仅限 Semantic Collection）。
- 确保 JSON 中的引用格式为 `"{primitive.color.blue.500}"` 这种标准格式。
- **关于资源引用**：由于 `asset.json` 已分离，`tokens.json` 中的 `"{asset.image.xxx}"` 引用在 Figma 中将被统一转换为 **FLOAT** 类型，且值固定为 **0**。这旨在保持 Variables 结构的完整性。
- 插件会自动将 JSON 的点号路径（.）转换为 Figma 的层级路径（/）。
