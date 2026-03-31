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
  String get homePageTitle => '试验台';

  @override
  String get homePageSubtitle => 'Flutter 技术预研入口';

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
  String get tabHome => '试验台';

  @override
  String get labThemePlaygroundTitle => '主题调试台';

  @override
  String get labThemePlaygroundSubtitle => '验证运行时主题切换、mode 合并和提示词生成链路。';

  @override
  String get labLogsTitle => '运行时日志';

  @override
  String get labLogsSubtitle => '在真机上验证日志写入、导出链路和原生分享行为。';

  @override
  String get labDebugTitle => '主题观测台';

  @override
  String get labDebugSubtitle => '集中查看 manifest 字段、token 路径和运行时解析后的颜色结果。';

  @override
  String get labUsbDriveTitle => 'U 盘读取实验';

  @override
  String get labUsbDriveSubtitle => '验证 iOS 和安卓是否能读取外接 U 盘中的内容。';

  @override
  String get labTesterTitle => '重置沙盒';

  @override
  String get labTesterSubtitle => '把恢复安装等破坏性调试动作集中放在这里，不混进设置页。';

  @override
  String get tabList => '控件';

  @override
  String get usbDrivePageTitle => 'U 盘读取实验';

  @override
  String get usbDrivePageSubtitle => '跨平台外接存储验证';

  @override
  String get usbDriveIntroTitle => '实验目标';

  @override
  String get usbDriveIntroBody => '这个页面用于验证 Demo 是否能在 iOS 和安卓上枚举并读取外接 U 盘中的内容。';

  @override
  String get usbDriveIosStatusTitle => 'iOS 状态';

  @override
  String get usbDriveIosStatusBody =>
      '待验证。下一步需要确认当前 app 沙盒下是否能通过 Files 导入或外接磁盘访问链路读取内容。';

  @override
  String get usbDriveAndroidStatusTitle => '安卓状态';

  @override
  String get usbDriveAndroidStatusBody =>
      '待验证。下一步需要确认 USB OTG 挂载可见性，以及 Flutter 是否能读到对应文档内容。';

  @override
  String get usbDriveActionTitle => '开始实验';

  @override
  String get usbDriveActionBody =>
      '在 iOS 上会调起系统文件选择器。若外接 U 盘已在 Files 中可见，就可以直接选择其中的文件并读取预览。';

  @override
  String get usbDrivePickButton => '选择文件';

  @override
  String get usbDrivePicking => '选择中...';

  @override
  String get usbDrivePickUnsupported => '当前仅实现了 iOS 文件选择实验';

  @override
  String get usbDrivePickFailed => '读取失败';

  @override
  String get usbDrivePickedResultTitle => '读取结果';

  @override
  String get usbDrivePickedName => '文件名';

  @override
  String get usbDrivePickedSize => '大小';

  @override
  String get usbDrivePickedPath => '路径';

  @override
  String get usbDrivePickedPreview => '文本预览';

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
  String get logsExportUnavailable => '当前没有可导出的日志文件。';

  @override
  String get logsExportSuccess => '已打开系统分享面板。';

  @override
  String get logsExportFailed => '导出日志失败。';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsPageSubtitle => '主题与语言';

  @override
  String get settingsBannerTitle => '设置';

  @override
  String get settingsBannerSubtitle => '通用配置与开发工具';

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

  @override
  String get testerClearRecordsTitle => '删除所有记录';

  @override
  String get testerClearRecordsConfirmTitle => '删除所有记录？';

  @override
  String get testerClearRecordsConfirmBody =>
      '这会清空日志文件、已生成主题记录，以及下载到本地的所有主题资源。';

  @override
  String get testerClearRecordsConfirmAction => '确认删除';

  @override
  String get testerClearRecordsDone => '已清空日志和所有主题记录';

  @override
  String get onboardingDemoSettingsTitle => '引导页 Demo';

  @override
  String get onboardingDemoSettingsSubtitle => '使用 6 步模拟流程验证引导页模块';

  @override
  String get onboardingDemoSkip => '跳过';

  @override
  String get onboardingDemoCompleteMessage => '引导流程完成';

  @override
  String get onboardingP1Title => '欢迎使用 Pantas';

  @override
  String get onboardingP1Desc => '为了您更好的使用体验，请先完成以下几项必要的配置工作。';

  @override
  String get onboardingP1Action => '开始配置';

  @override
  String get onboardingP2Title => '存储权限';

  @override
  String get onboardingP2Desc => 'Pantas 需要存储访问权限，以便读取和管理您的文件。请点击下方按钮完成授权。';

  @override
  String get onboardingP2Action => '开启权限';

  @override
  String get onboardingP3Title => '选择数据存储位置';

  @override
  String get onboardingP3Desc =>
      '请选择一个文件夹，用来保存您的设置、游戏列表、抓取媒体等。建议文件夹命名为 Pantas。';

  @override
  String get onboardingP3Action => '选择文件夹';

  @override
  String get onboardingP4Title => '选择游戏存放位置';

  @override
  String get onboardingP4Desc => '请选择一个文件夹，用来保存您的游戏文件（rom）。建议文件夹命名为 roms。';

  @override
  String get onboardingP4Hint => '配置完后至少需要添加一个游戏文件，否则应用将无法启动。';

  @override
  String get onboardingP4Action => '选择文件夹';

  @override
  String get onboardingP5Title => '创建游戏平台目录？';

  @override
  String get onboardingP5Desc =>
      '将在您的 roms 文件夹中为所有支持的游戏平台创建子目录，并在每个平台文件夹内自动生成 systeminfo.txt 系统配置文件。如果您选择跳过，需要手动创建这些文件。';

  @override
  String get onboardingP5Action => '立即创建';

  @override
  String get onboardingP5Skip => '跳过';

  @override
  String get onboardingP6Title => '配置完成！';

  @override
  String get onboardingP6Desc => '恭喜！Pantas 已经配置完成，现在可以开始使用了。';

  @override
  String get onboardingP6Hint =>
      '您还需要安装各个游戏平台对应的模拟器。部分模拟器可能需要额外配置 ROMs 文件夹的访问权限，否则游戏可能无法启动。';

  @override
  String get onboardingP6Action => '开始使用';
}
