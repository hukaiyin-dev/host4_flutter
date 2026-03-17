// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Host4 Flutter Demo';

  @override
  String get themeBootstrapFailed => 'Theme bootstrap failed';

  @override
  String get homePageTitle => 'Home';

  @override
  String get homePageSubtitle => 'Theme story';

  @override
  String get listPageTitle => 'List';

  @override
  String get listPageSubtitle => 'Component density';

  @override
  String get themePlaygroundPageTitle => 'Theme Playground';

  @override
  String get themePlaygroundPageSubtitle => 'Runtime switching';

  @override
  String get languagePageTitle => 'Language';

  @override
  String get languagePageSubtitle => 'Localization settings';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get bannerBadgeAiTheme => 'AI Theme';

  @override
  String get homeHeroTitle => 'Prompt to theme, without changing UI structure.';

  @override
  String get homeHeroSubtitle =>
      'The same component tree is being re-skinned by tokens.json.';

  @override
  String get featuredModulesTitle => 'Featured Modules';

  @override
  String get featuredModulesSubtitle =>
      'Cards, text hierarchy and button styling should all react.';

  @override
  String get compareButton => 'Compare';

  @override
  String get featureThemeChainTitle => 'Theme chain';

  @override
  String get featureThemeChainSubtitle => 'tokens.json -> RuntimeTheme -> UI';

  @override
  String get inspectButton => 'Inspect';

  @override
  String get featureVisualDeltaTitle => 'Visual delta';

  @override
  String get featureVisualDeltaSubtitle =>
      'Switch between default and grassland at runtime.';

  @override
  String get switchButton => 'Switch';

  @override
  String get whyDemoMattersTitle => 'Why this demo matters';

  @override
  String get whyDemoMattersBody =>
      'The app shell, cards and banners stay structurally identical while the theme package swaps color, spacing and image references.';

  @override
  String get useCurrentThemeButton => 'Use current theme';

  @override
  String get previewRemoteFlowButton => 'Preview remote flow';

  @override
  String get searchHint => 'Search tokens, pages or components';

  @override
  String get componentInventoryTitle => 'Component Inventory';

  @override
  String get componentInventorySubtitle =>
      'TextField, SearchBar, ListCell and Card are already themed.';

  @override
  String get listDiagnosticsTitle => 'List diagnostics';

  @override
  String get listDiagnosticsBody =>
      'This page is tuned to expose spacing rhythm, subtle surfaces and input contrast.';

  @override
  String get promptExampleText =>
      'Switch to the grassland theme, emphasizing wind-blown fields, soft greens and lighter card depth.';

  @override
  String get localThemesBadge => 'Local themes';

  @override
  String currentThemeTitle(Object themeName) {
    return 'Current theme: $themeName';
  }

  @override
  String get currentThemeSubtitle =>
      'This stage only reads local tokens.json and keeps the parser chain reusable.';

  @override
  String get switchThemesTitle => 'Switch Themes';

  @override
  String get switchThemesSubtitle =>
      'The manager parses the matching local tokens.json file each time.';

  @override
  String get switchModeTitle => 'Switch Mode';

  @override
  String get switchModeSubtitle =>
      'Alias shared and the active mode are merged before component references resolve.';

  @override
  String get promptInputTitle => 'Prompt input';

  @override
  String get promptInputSubtitle =>
      'The button is intentionally a stub in phase one. Remote generation comes later.';

  @override
  String get promptHint => 'Describe a mood, palette or scene';

  @override
  String get generateThemeButton => 'Generate Theme';

  @override
  String get runtimeTokenPreviewTitle => 'Runtime token preview';

  @override
  String currentModeLabel(Object modeLabel) {
    return 'Current mode: $modeLabel';
  }

  @override
  String get primaryLabel => 'Primary';

  @override
  String get secondaryLabel => 'Secondary';

  @override
  String get accentLabel => 'Accent';

  @override
  String get surfaceLabel => 'Surface';

  @override
  String get mutedLabel => 'Muted';

  @override
  String get themeRegistryTitle => 'Theme registry';

  @override
  String get themeRegistrySubtitle =>
      'Maps theme id to local tokens.json and loads them on demand.';

  @override
  String get badgeP0 => 'P0';

  @override
  String get tokenParserTitle => 'Token parser';

  @override
  String get tokenParserSubtitle =>
      'Resolves primitive, alias and component values into runtime fields.';

  @override
  String get badgeReady => 'Ready';

  @override
  String get themeScopeTitle => 'ThemeScope';

  @override
  String get themeScopeSubtitle =>
      'InheritedNotifier refreshes widgets without rebooting the app.';

  @override
  String get badgeLive => 'Live';

  @override
  String get playgroundTitle => 'Playground';

  @override
  String get playgroundSubtitle =>
      'Keeps the prompt UI visible while remote generation stays stubbed.';

  @override
  String get badgeStub => 'Stub';

  @override
  String get languageSettingsTitle => 'App language';

  @override
  String get languageSettingsSubtitle =>
      'Use this page to switch the demo language without restarting the app.';

  @override
  String currentLanguageLabel(Object languageName) {
    return 'Current language: $languageName';
  }

  @override
  String get englishLanguageName => 'English';

  @override
  String get chineseLanguageName => 'Simplified Chinese';

  @override
  String get switchToEnglishButton => 'English';

  @override
  String get switchToChineseButton => '简体中文';
}
