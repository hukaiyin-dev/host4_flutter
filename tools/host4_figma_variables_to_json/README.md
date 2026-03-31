# Host4 Figma variables to json

## 核心功能
自动化将 Figma Variables 导出为符合项目规范的 `tokens.json`。

## 安装步骤
- 在 Figma 桌面版中，点击顶部菜单：**Plugins > Development > Import plugin from manifest...**。
- 选择本项目目录下的 `manifest.json` 文件。
- 插件将出现在你的本地开发插件列表中。

## 使用方法
- 在 Figma 文件中运行 **Host4 Figma variables to json**。
- 点击 **导出 JSON** 按钮。
- 插件将处理并自动下载 `tokens.json` 文件。

## 导出规则
- **集合匹配**：扫描名为 `Primitive`、`Semantic`、`Component` 的集合。
- **模式还原**：
  - `Semantic`：根据模式名称（需包含 `Light` 和 `Dark`）生成 `{ "light": ..., "dark": ... }` 结构。
  - `Primitive` / `Component`：导出第一个模式的值。
- **引用还原**：将 Figma Alias 还原为 `{collection.path}` 格式（例如 `{primitive.color.blue.500}`）。
- **颜色处理**：将 Figma 的 RGBA 对象转换为十六进制字符串（如 `#RRGGBB` 或 `#RRGGBBAA`）。
- **路径重组**：将斜线路径（/）还原为 JSON 嵌套对象。
