// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Host4 Flutter 示例';

  @override
  String get themeBootstrapFailed => '主题初始化失败';

  @override
  String get homePageTitle => '首页';

  @override
  String get homePageSubtitle => '主题故事';

  @override
  String get listPageTitle => '控件';

  @override
  String get listPageSubtitle => '控件展示';

  @override
  String get componentButtonsTitle => '按钮';

  @override
  String get componentButtonsSubtitle => '变体、状态与图标组合';

  @override
  String get sectionVariants => '变体';

  @override
  String get sectionWithIcon => '带图标';

  @override
  String get sectionExpanded => '展开宽度';

  @override
  String get sectionDisabled => '禁用状态';

  @override
  String get themePlaygroundPageTitle => '主题调试台';

  @override
  String get themePlaygroundPageSubtitle => '运行时切换';

  @override
  String get languagePageTitle => '语言';

  @override
  String get languagePageSubtitle => '本地化设置';

  @override
  String get modeLight => '浅色';

  @override
  String get modeDark => '深色';

  @override
  String get bannerBadgeAiTheme => 'AI 主题';

  @override
  String get homeHeroTitle => '不改 UI 结构，也能从提示词切换主题。';

  @override
  String get homeHeroSubtitle => '同一套组件树正在由 tokens.json 重新换肤。';

  @override
  String get featuredModulesTitle => '精选模块';

  @override
  String get featuredModulesSubtitle => '卡片、文字层级和按钮样式都会一起响应主题变化。';

  @override
  String get compareButton => '对比';

  @override
  String get featureThemeChainTitle => '主题链路';

  @override
  String get featureThemeChainSubtitle => 'tokens.json -> RuntimeTheme -> UI';

  @override
  String get inspectButton => '查看';

  @override
  String get featureVisualDeltaTitle => '视觉差异';

  @override
  String get featureVisualDeltaSubtitle => '在运行时切换 default 和 grassland 主题。';

  @override
  String get switchButton => '切换';

  @override
  String get whyDemoMattersTitle => '为什么这个 Demo 重要';

  @override
  String get whyDemoMattersBody =>
      '应用外壳、卡片和 Banner 的结构保持不变，只通过主题包切换颜色、间距和图片引用。';

  @override
  String get useCurrentThemeButton => '使用当前主题';

  @override
  String get previewRemoteFlowButton => '预览远程流程';

  @override
  String get searchHint => '搜索 token、页面或组件';

  @override
  String get componentInventoryTitle => '组件清单';

  @override
  String get componentInventorySubtitle =>
      'TextField、SearchBar、ListCell 和 Card 已经完成主题接入。';

  @override
  String get listDiagnosticsTitle => '列表诊断';

  @override
  String get listDiagnosticsBody => '这个页面主要用来暴露间距节奏、层级表面和输入框对比度。';

  @override
  String get promptExampleText => '将主题换为草原主题，强调风吹草浪、柔和绿色和更轻的卡片层级。';

  @override
  String get localThemesBadge => '本地主题';

  @override
  String currentThemeTitle(Object themeName) {
    return '当前主题：$themeName';
  }

  @override
  String get currentThemeSubtitle => '当前阶段只读取本地 tokens.json，并保持解析链路可复用。';

  @override
  String get switchThemesTitle => '切换主题';

  @override
  String get switchThemesSubtitle => '管理器会在每次切换时重新解析对应的本地 tokens.json。';

  @override
  String get switchModeTitle => '切换模式';

  @override
  String get switchModeSubtitle => '组件引用解析前，会先合并 alias shared 和当前 mode。';

  @override
  String get promptInputTitle => '提示词输入';

  @override
  String get promptInputSubtitle => '这个按钮在第一阶段有意保留为占位，远程生成能力后续再接。';

  @override
  String get promptHint => '描述一种氛围、配色或场景';

  @override
  String get generateThemeButton => '生成主题';

  @override
  String get runtimeTokenPreviewTitle => '运行时 Token 预览';

  @override
  String currentModeLabel(Object modeLabel) {
    return '当前模式：$modeLabel';
  }

  @override
  String get primaryLabel => '主色';

  @override
  String get secondaryLabel => '辅助色';

  @override
  String get accentLabel => '强调色';

  @override
  String get surfaceLabel => '表面色';

  @override
  String get mutedLabel => '弱化色';

  @override
  String get themeRegistryTitle => '主题注册表';

  @override
  String get themeRegistrySubtitle => '按 theme id 映射本地 tokens.json，并在需要时加载。';

  @override
  String get badgeP0 => 'P0';

  @override
  String get tokenParserTitle => 'Token 解析器';

  @override
  String get tokenParserSubtitle => '把 primitive、alias 和 component 值解析成运行时字段。';

  @override
  String get badgeReady => '就绪';

  @override
  String get themeScopeTitle => 'ThemeScope';

  @override
  String get themeScopeSubtitle => 'InheritedNotifier 可以在不重启应用的情况下刷新组件。';

  @override
  String get badgeLive => '生效中';

  @override
  String get playgroundTitle => '调试台';

  @override
  String get playgroundSubtitle => '在远程生成还未接入前，先把提示词 UI 保留出来。';

  @override
  String get badgeStub => '占位';

  @override
  String get languageSettingsTitle => '应用语言';

  @override
  String get languageSettingsSubtitle => '在这个页面切换 Demo 语言，无需重启应用。';

  @override
  String currentLanguageLabel(Object languageName) {
    return '当前语言：$languageName';
  }

  @override
  String get englishLanguageName => '英文';

  @override
  String get chineseLanguageName => '简体中文';

  @override
  String get switchToEnglishButton => 'English';

  @override
  String get switchToChineseButton => '简体中文';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get languageFollowSystemSubtitle => '自动匹配设备语言';

  @override
  String get languageManualSection => '手动选择';

  @override
  String get tabHome => '首页';

  @override
  String get tabList => '列表';

  @override
  String get tabSettings => '设置';

  @override
  String get logsPageTitle => '日志';

  @override
  String get logsPageSubtitle => '运行时日志输出';

  @override
  String get logsExportButton => '导出';

  @override
  String get logsClearButton => '清空';

  @override
  String get logsClearConfirmTitle => '清空日志？';

  @override
  String get logsClearConfirmBody => '所有日志记录将被永久删除。';

  @override
  String get logsClearConfirmAction => '清空';

  @override
  String get cancel => '取消';

  @override
  String get logsEmptyMessage => '暂无日志';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsPageSubtitle => '主题与语言';

  @override
  String get settingsBannerTitle => '外观设置';

  @override
  String get settingsBannerSubtitle => '在下方切换主题或应用语言。';

  @override
  String get testerPageTitle => 'Tester';

  @override
  String get testerPageSubtitle => '开发工具';

  @override
  String get testerResetTitle => '恢复初次安装';

  @override
  String get testerResetSubtitle => '清除所有已保存的数据';

  @override
  String get testerResetConfirmTitle => '恢复初次安装？';

  @override
  String get testerResetConfirmBody => '所有已保存的偏好设置将被清除。';

  @override
  String get testerResetConfirmAction => '恢复';
}
