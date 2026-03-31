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
  String get homePageTitle => 'Lab';

  @override
  String get homePageSubtitle => 'Flutter technical experiments';

  @override
  String get listPageTitle => 'Components';

  @override
  String get listPageSubtitle => 'Component gallery';

  @override
  String get componentButtonsTitle => 'Buttons';

  @override
  String get componentButtonsSubtitle => 'Variants, states & icon combinations';

  @override
  String get sectionVariants => 'Variants';

  @override
  String get sectionWithIcon => 'With Icon';

  @override
  String get sectionExpanded => 'Expanded';

  @override
  String get sectionDisabled => 'Disabled';

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

  @override
  String get languageFollowSystem => 'Follow System';

  @override
  String get languageFollowSystemSubtitle =>
      'Automatically matches your device language';

  @override
  String get languageManualSection => 'Manual Selection';

  @override
  String get tabHome => 'Lab';

  @override
  String get labThemePlaygroundTitle => 'Theme Playground';

  @override
  String get labThemePlaygroundSubtitle =>
      'Try runtime theme switching, mode merge and prompt-driven generation flow.';

  @override
  String get labLogsTitle => 'Runtime Logs';

  @override
  String get labLogsSubtitle =>
      'Verify local log writing, export flow and native share behavior on device.';

  @override
  String get labDebugTitle => 'Theme Inspector';

  @override
  String get labDebugSubtitle =>
      'Inspect manifest fields, token paths and resolved runtime colors in one place.';

  @override
  String get labUsbDriveTitle => 'USB Drive Experiment';

  @override
  String get labUsbDriveSubtitle =>
      'Validate whether iOS and Android can read files from an attached USB drive.';

  @override
  String get labTesterTitle => 'Reset Sandbox';

  @override
  String get labTesterSubtitle =>
      'Run destructive test actions like reset-install without mixing them into Settings.';

  @override
  String get tabList => 'Components';

  @override
  String get usbDrivePageTitle => 'USB Drive Experiment';

  @override
  String get usbDrivePageSubtitle =>
      'Cross-platform external storage validation';

  @override
  String get usbDriveIntroTitle => 'Experiment Goal';

  @override
  String get usbDriveIntroBody =>
      'Use this page to validate whether the demo can enumerate and read content from a connected USB drive on iOS and Android.';

  @override
  String get usbDriveIosStatusTitle => 'iOS status';

  @override
  String get usbDriveIosStatusBody =>
      'Pending verification. The next step is to confirm whether Files-based import or external drive access is available in the current app sandbox.';

  @override
  String get usbDriveAndroidStatusTitle => 'Android status';

  @override
  String get usbDriveAndroidStatusBody =>
      'Pending verification. The next step is to confirm USB OTG mount visibility and readable document access from Flutter.';

  @override
  String get usbDriveActionTitle => 'Run Experiment';

  @override
  String get usbDriveActionBody =>
      'On iOS this opens the system document picker. If the external USB drive is visible in Files, you can choose a file and read a preview.';

  @override
  String get usbDrivePickButton => 'Choose File';

  @override
  String get usbDrivePicking => 'Picking...';

  @override
  String get usbDrivePickUnsupported =>
      'Only the iOS picker experiment is implemented right now';

  @override
  String get usbDrivePickFailed => 'Read failed';

  @override
  String get usbDrivePickedResultTitle => 'Result';

  @override
  String get usbDrivePickedName => 'Name';

  @override
  String get usbDrivePickedSize => 'Size';

  @override
  String get usbDrivePickedPath => 'Path';

  @override
  String get usbDrivePickedPreview => 'Preview';

  @override
  String get tabSettings => 'Settings';

  @override
  String get logsPageTitle => 'Logs';

  @override
  String get logsPageSubtitle => 'Runtime log output';

  @override
  String get logsExportButton => 'Export';

  @override
  String get logsClearButton => 'Clear';

  @override
  String get logsClearConfirmTitle => 'Clear logs?';

  @override
  String get logsClearConfirmBody =>
      'All log records will be permanently deleted.';

  @override
  String get logsClearConfirmAction => 'Clear';

  @override
  String get cancel => 'Cancel';

  @override
  String get logsEmptyMessage => 'No logs yet.';

  @override
  String get logsExportUnavailable => 'No log file available to export.';

  @override
  String get logsExportSuccess => 'System share sheet opened.';

  @override
  String get logsExportFailed => 'Failed to export logs.';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsPageSubtitle => 'Theme & Language';

  @override
  String get settingsBannerTitle => 'Settings';

  @override
  String get settingsBannerSubtitle =>
      'General preferences and developer tools';

  @override
  String get testerPageTitle => 'Tester';

  @override
  String get testerPageSubtitle => 'Development tools';

  @override
  String get testerResetTitle => 'Reset Install';

  @override
  String get testerResetSubtitle => 'Clear all saved data';

  @override
  String get testerResetConfirmTitle => 'Reset to defaults?';

  @override
  String get testerResetConfirmBody => 'All saved preferences will be cleared.';

  @override
  String get testerResetConfirmAction => 'Reset';

  @override
  String get testerClearRecordsTitle => 'Delete All Records';

  @override
  String get testerClearRecordsConfirmTitle => 'Delete all records?';

  @override
  String get testerClearRecordsConfirmBody =>
      'This clears the log file, generated theme records, and all downloaded theme assets.';

  @override
  String get testerClearRecordsConfirmAction => 'Delete';

  @override
  String get testerClearRecordsDone => 'Cleared logs and all theme records';

  @override
  String get onboardingDemoSettingsTitle => 'Onboarding Demo';

  @override
  String get onboardingDemoSettingsSubtitle =>
      'Test the onboarding module with a 6-step simulated flow';

  @override
  String get onboardingDemoSkip => 'Skip';

  @override
  String get onboardingDemoCompleteMessage => 'Onboarding completed';

  @override
  String get onboardingP1Title => 'Welcome to Pantas';

  @override
  String get onboardingP1Desc =>
      'To get you started, please complete a few essential setup steps.';

  @override
  String get onboardingP1Action => 'Let\'s Go';

  @override
  String get onboardingP2Title => 'Storage Permission';

  @override
  String get onboardingP2Desc =>
      'Pantas needs storage access to read and manage your files. Tap the button below to grant access.';

  @override
  String get onboardingP2Action => 'Grant Permission';

  @override
  String get onboardingP3Title => 'Choose Data Folder';

  @override
  String get onboardingP3Desc =>
      'Select a folder to store your settings, game lists and media. We recommend naming it Pantas.';

  @override
  String get onboardingP3Action => 'Choose Folder';

  @override
  String get onboardingP4Title => 'Choose ROMs Folder';

  @override
  String get onboardingP4Desc =>
      'Select a folder to store your game files (ROMs). We recommend naming it roms.';

  @override
  String get onboardingP4Hint =>
      'You will need at least one game file after setup, otherwise the app may not launch.';

  @override
  String get onboardingP4Action => 'Choose Folder';

  @override
  String get onboardingP5Title => 'Create Platform Directories?';

  @override
  String get onboardingP5Desc =>
      'Subdirectories for all supported game platforms will be created inside your ROMs folder, each with an auto-generated systeminfo.txt config file. If you skip this, you will need to create these files manually.';

  @override
  String get onboardingP5Action => 'Create Now';

  @override
  String get onboardingP5Skip => 'Skip';

  @override
  String get onboardingP6Title => 'All Set!';

  @override
  String get onboardingP6Desc => 'Pantas is configured and ready to use.';

  @override
  String get onboardingP6Hint =>
      'You still need to install an emulator for each game platform. Some emulators may require additional ROM folder access permissions, otherwise games may not launch.';

  @override
  String get onboardingP6Action => 'Start Using';
}
