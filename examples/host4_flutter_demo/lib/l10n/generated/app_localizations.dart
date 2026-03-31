import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Host4 Flutter Demo'**
  String get appTitle;

  /// No description provided for @themeBootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Theme bootstrap failed'**
  String get themeBootstrapFailed;

  /// No description provided for @homePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get homePageTitle;

  /// No description provided for @homePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter technical experiments'**
  String get homePageSubtitle;

  /// No description provided for @listPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get listPageTitle;

  /// No description provided for @listPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Component gallery'**
  String get listPageSubtitle;

  /// No description provided for @componentButtonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get componentButtonsTitle;

  /// No description provided for @componentButtonsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Variants, states & icon combinations'**
  String get componentButtonsSubtitle;

  /// No description provided for @sectionVariants.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get sectionVariants;

  /// No description provided for @sectionWithIcon.
  ///
  /// In en, this message translates to:
  /// **'With Icon'**
  String get sectionWithIcon;

  /// No description provided for @sectionExpanded.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get sectionExpanded;

  /// No description provided for @sectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get sectionDisabled;

  /// No description provided for @themePlaygroundPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Playground'**
  String get themePlaygroundPageTitle;

  /// No description provided for @themePlaygroundPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime switching'**
  String get themePlaygroundPageSubtitle;

  /// No description provided for @languagePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePageTitle;

  /// No description provided for @languagePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Localization settings'**
  String get languagePageSubtitle;

  /// No description provided for @modeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get modeLight;

  /// No description provided for @modeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get modeDark;

  /// No description provided for @bannerBadgeAiTheme.
  ///
  /// In en, this message translates to:
  /// **'AI Theme'**
  String get bannerBadgeAiTheme;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt to theme, without changing UI structure.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The same component tree is being re-skinned by tokens.json.'**
  String get homeHeroSubtitle;

  /// No description provided for @featuredModulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Modules'**
  String get featuredModulesTitle;

  /// No description provided for @featuredModulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cards, text hierarchy and button styling should all react.'**
  String get featuredModulesSubtitle;

  /// No description provided for @compareButton.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compareButton;

  /// No description provided for @featureThemeChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme chain'**
  String get featureThemeChainTitle;

  /// No description provided for @featureThemeChainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'tokens.json -> RuntimeTheme -> UI'**
  String get featureThemeChainSubtitle;

  /// No description provided for @inspectButton.
  ///
  /// In en, this message translates to:
  /// **'Inspect'**
  String get inspectButton;

  /// No description provided for @featureVisualDeltaTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual delta'**
  String get featureVisualDeltaTitle;

  /// No description provided for @featureVisualDeltaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between default and grassland at runtime.'**
  String get featureVisualDeltaSubtitle;

  /// No description provided for @switchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchButton;

  /// No description provided for @whyDemoMattersTitle.
  ///
  /// In en, this message translates to:
  /// **'Why this demo matters'**
  String get whyDemoMattersTitle;

  /// No description provided for @whyDemoMattersBody.
  ///
  /// In en, this message translates to:
  /// **'The app shell, cards and banners stay structurally identical while the theme package swaps color, spacing and image references.'**
  String get whyDemoMattersBody;

  /// No description provided for @useCurrentThemeButton.
  ///
  /// In en, this message translates to:
  /// **'Use current theme'**
  String get useCurrentThemeButton;

  /// No description provided for @previewRemoteFlowButton.
  ///
  /// In en, this message translates to:
  /// **'Preview remote flow'**
  String get previewRemoteFlowButton;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tokens, pages or components'**
  String get searchHint;

  /// No description provided for @componentInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Component Inventory'**
  String get componentInventoryTitle;

  /// No description provided for @componentInventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'TextField, SearchBar, ListCell and Card are already themed.'**
  String get componentInventorySubtitle;

  /// No description provided for @listDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'List diagnostics'**
  String get listDiagnosticsTitle;

  /// No description provided for @listDiagnosticsBody.
  ///
  /// In en, this message translates to:
  /// **'This page is tuned to expose spacing rhythm, subtle surfaces and input contrast.'**
  String get listDiagnosticsBody;

  /// No description provided for @promptExampleText.
  ///
  /// In en, this message translates to:
  /// **'Switch to the grassland theme, emphasizing wind-blown fields, soft greens and lighter card depth.'**
  String get promptExampleText;

  /// No description provided for @localThemesBadge.
  ///
  /// In en, this message translates to:
  /// **'Local themes'**
  String get localThemesBadge;

  /// No description provided for @currentThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Current theme: {themeName}'**
  String currentThemeTitle(Object themeName);

  /// No description provided for @currentThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This stage only reads local tokens.json and keeps the parser chain reusable.'**
  String get currentThemeSubtitle;

  /// No description provided for @switchThemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Themes'**
  String get switchThemesTitle;

  /// No description provided for @switchThemesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The manager parses the matching local tokens.json file each time.'**
  String get switchThemesSubtitle;

  /// No description provided for @switchModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Mode'**
  String get switchModeTitle;

  /// No description provided for @switchModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Alias shared and the active mode are merged before component references resolve.'**
  String get switchModeSubtitle;

  /// No description provided for @promptInputTitle.
  ///
  /// In en, this message translates to:
  /// **'Prompt input'**
  String get promptInputTitle;

  /// No description provided for @promptInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The button is intentionally a stub in phase one. Remote generation comes later.'**
  String get promptInputSubtitle;

  /// No description provided for @promptHint.
  ///
  /// In en, this message translates to:
  /// **'Describe a mood, palette or scene'**
  String get promptHint;

  /// No description provided for @generateThemeButton.
  ///
  /// In en, this message translates to:
  /// **'Generate Theme'**
  String get generateThemeButton;

  /// No description provided for @runtimeTokenPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime token preview'**
  String get runtimeTokenPreviewTitle;

  /// No description provided for @currentModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Current mode: {modeLabel}'**
  String currentModeLabel(Object modeLabel);

  /// No description provided for @primaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryLabel;

  /// No description provided for @secondaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondaryLabel;

  /// No description provided for @accentLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get accentLabel;

  /// No description provided for @surfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get surfaceLabel;

  /// No description provided for @mutedLabel.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get mutedLabel;

  /// No description provided for @themeRegistryTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme registry'**
  String get themeRegistryTitle;

  /// No description provided for @themeRegistrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Maps theme id to local tokens.json and loads them on demand.'**
  String get themeRegistrySubtitle;

  /// No description provided for @badgeP0.
  ///
  /// In en, this message translates to:
  /// **'P0'**
  String get badgeP0;

  /// No description provided for @tokenParserTitle.
  ///
  /// In en, this message translates to:
  /// **'Token parser'**
  String get tokenParserTitle;

  /// No description provided for @tokenParserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resolves primitive, alias and component values into runtime fields.'**
  String get tokenParserSubtitle;

  /// No description provided for @badgeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get badgeReady;

  /// No description provided for @themeScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'ThemeScope'**
  String get themeScopeTitle;

  /// No description provided for @themeScopeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'InheritedNotifier refreshes widgets without rebooting the app.'**
  String get themeScopeSubtitle;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get badgeLive;

  /// No description provided for @playgroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Playground'**
  String get playgroundTitle;

  /// No description provided for @playgroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeps the prompt UI visible while remote generation stays stubbed.'**
  String get playgroundSubtitle;

  /// No description provided for @badgeStub.
  ///
  /// In en, this message translates to:
  /// **'Stub'**
  String get badgeStub;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use this page to switch the demo language without restarting the app.'**
  String get languageSettingsSubtitle;

  /// No description provided for @currentLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current language: {languageName}'**
  String currentLanguageLabel(Object languageName);

  /// No description provided for @englishLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageName;

  /// No description provided for @chineseLanguageName.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get chineseLanguageName;

  /// No description provided for @switchToEnglishButton.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get switchToEnglishButton;

  /// No description provided for @switchToChineseButton.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get switchToChineseButton;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageFollowSystem;

  /// No description provided for @languageFollowSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically matches your device language'**
  String get languageFollowSystemSubtitle;

  /// No description provided for @languageManualSection.
  ///
  /// In en, this message translates to:
  /// **'Manual Selection'**
  String get languageManualSection;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get tabHome;

  /// No description provided for @labThemePlaygroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Playground'**
  String get labThemePlaygroundTitle;

  /// No description provided for @labThemePlaygroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try runtime theme switching, mode merge and prompt-driven generation flow.'**
  String get labThemePlaygroundSubtitle;

  /// No description provided for @labLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime Logs'**
  String get labLogsTitle;

  /// No description provided for @labLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify local log writing, export flow and native share behavior on device.'**
  String get labLogsSubtitle;

  /// No description provided for @labDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Inspector'**
  String get labDebugTitle;

  /// No description provided for @labDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspect manifest fields, token paths and resolved runtime colors in one place.'**
  String get labDebugSubtitle;

  /// No description provided for @labUsbDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'USB Drive Experiment'**
  String get labUsbDriveTitle;

  /// No description provided for @labUsbDriveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Validate whether iOS and Android can read files from an attached USB drive.'**
  String get labUsbDriveSubtitle;

  /// No description provided for @labTesterTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Sandbox'**
  String get labTesterTitle;

  /// No description provided for @labTesterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run destructive test actions like reset-install without mixing them into Settings.'**
  String get labTesterSubtitle;

  /// No description provided for @tabList.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get tabList;

  /// No description provided for @usbDrivePageTitle.
  ///
  /// In en, this message translates to:
  /// **'USB Drive Experiment'**
  String get usbDrivePageTitle;

  /// No description provided for @usbDrivePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cross-platform external storage validation'**
  String get usbDrivePageSubtitle;

  /// No description provided for @usbDriveIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Experiment Goal'**
  String get usbDriveIntroTitle;

  /// No description provided for @usbDriveIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Use this page to validate whether the demo can enumerate and read content from a connected USB drive on iOS and Android.'**
  String get usbDriveIntroBody;

  /// No description provided for @usbDriveIosStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS status'**
  String get usbDriveIosStatusTitle;

  /// No description provided for @usbDriveIosStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Pending verification. The next step is to confirm whether Files-based import or external drive access is available in the current app sandbox.'**
  String get usbDriveIosStatusBody;

  /// No description provided for @usbDriveAndroidStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Android status'**
  String get usbDriveAndroidStatusTitle;

  /// No description provided for @usbDriveAndroidStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Pending verification. The next step is to confirm USB OTG mount visibility and readable document access from Flutter.'**
  String get usbDriveAndroidStatusBody;

  /// No description provided for @usbDriveActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Run Experiment'**
  String get usbDriveActionTitle;

  /// No description provided for @usbDriveActionBody.
  ///
  /// In en, this message translates to:
  /// **'On iOS this opens the system document picker. If the external USB drive is visible in Files, you can choose a file and read a preview.'**
  String get usbDriveActionBody;

  /// No description provided for @usbDrivePickButton.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get usbDrivePickButton;

  /// No description provided for @usbDrivePicking.
  ///
  /// In en, this message translates to:
  /// **'Picking...'**
  String get usbDrivePicking;

  /// No description provided for @usbDrivePickUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Only the iOS picker experiment is implemented right now'**
  String get usbDrivePickUnsupported;

  /// No description provided for @usbDrivePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Read failed'**
  String get usbDrivePickFailed;

  /// No description provided for @usbDrivePickedResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get usbDrivePickedResultTitle;

  /// No description provided for @usbDrivePickedName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get usbDrivePickedName;

  /// No description provided for @usbDrivePickedSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get usbDrivePickedSize;

  /// No description provided for @usbDrivePickedPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get usbDrivePickedPath;

  /// No description provided for @usbDrivePickedPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get usbDrivePickedPreview;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @logsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logsPageTitle;

  /// No description provided for @logsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime log output'**
  String get logsPageSubtitle;

  /// No description provided for @logsExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get logsExportButton;

  /// No description provided for @logsClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logsClearButton;

  /// No description provided for @logsClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear logs?'**
  String get logsClearConfirmTitle;

  /// No description provided for @logsClearConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All log records will be permanently deleted.'**
  String get logsClearConfirmBody;

  /// No description provided for @logsClearConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logsClearConfirmAction;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No logs yet.'**
  String get logsEmptyMessage;

  /// No description provided for @logsExportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No log file available to export.'**
  String get logsExportUnavailable;

  /// No description provided for @logsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'System share sheet opened.'**
  String get logsExportSuccess;

  /// No description provided for @logsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export logs.'**
  String get logsExportFailed;

  /// No description provided for @settingsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// No description provided for @settingsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme & Language'**
  String get settingsPageSubtitle;

  /// No description provided for @settingsBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsBannerTitle;

  /// No description provided for @settingsBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General preferences and developer tools'**
  String get settingsBannerSubtitle;

  /// No description provided for @testerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Tester'**
  String get testerPageTitle;

  /// No description provided for @testerPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Development tools'**
  String get testerPageSubtitle;

  /// No description provided for @testerResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Install'**
  String get testerResetTitle;

  /// No description provided for @testerResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all saved data'**
  String get testerResetSubtitle;

  /// No description provided for @testerResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults?'**
  String get testerResetConfirmTitle;

  /// No description provided for @testerResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All saved preferences will be cleared.'**
  String get testerResetConfirmBody;

  /// No description provided for @testerResetConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get testerResetConfirmAction;

  /// No description provided for @testerClearRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Records'**
  String get testerClearRecordsTitle;

  /// No description provided for @testerClearRecordsConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all records?'**
  String get testerClearRecordsConfirmTitle;

  /// No description provided for @testerClearRecordsConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This clears the log file, generated theme records, and all downloaded theme assets.'**
  String get testerClearRecordsConfirmBody;

  /// No description provided for @testerClearRecordsConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get testerClearRecordsConfirmAction;

  /// No description provided for @testerClearRecordsDone.
  ///
  /// In en, this message translates to:
  /// **'Cleared logs and all theme records'**
  String get testerClearRecordsDone;

  /// No description provided for @onboardingDemoSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Demo'**
  String get onboardingDemoSettingsTitle;

  /// No description provided for @onboardingDemoSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test the onboarding module with a 6-step simulated flow'**
  String get onboardingDemoSettingsSubtitle;

  /// No description provided for @onboardingDemoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingDemoSkip;

  /// No description provided for @onboardingDemoCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Onboarding completed'**
  String get onboardingDemoCompleteMessage;

  /// No description provided for @onboardingP1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pantas'**
  String get onboardingP1Title;

  /// No description provided for @onboardingP1Desc.
  ///
  /// In en, this message translates to:
  /// **'To get you started, please complete a few essential setup steps.'**
  String get onboardingP1Desc;

  /// No description provided for @onboardingP1Action.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go'**
  String get onboardingP1Action;

  /// No description provided for @onboardingP2Title.
  ///
  /// In en, this message translates to:
  /// **'Storage Permission'**
  String get onboardingP2Title;

  /// No description provided for @onboardingP2Desc.
  ///
  /// In en, this message translates to:
  /// **'Pantas needs storage access to read and manage your files. Tap the button below to grant access.'**
  String get onboardingP2Desc;

  /// No description provided for @onboardingP2Action.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get onboardingP2Action;

  /// No description provided for @onboardingP3Title.
  ///
  /// In en, this message translates to:
  /// **'Choose Data Folder'**
  String get onboardingP3Title;

  /// No description provided for @onboardingP3Desc.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to store your settings, game lists and media. We recommend naming it Pantas.'**
  String get onboardingP3Desc;

  /// No description provided for @onboardingP3Action.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get onboardingP3Action;

  /// No description provided for @onboardingP4Title.
  ///
  /// In en, this message translates to:
  /// **'Choose ROMs Folder'**
  String get onboardingP4Title;

  /// No description provided for @onboardingP4Desc.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to store your game files (ROMs). We recommend naming it roms.'**
  String get onboardingP4Desc;

  /// No description provided for @onboardingP4Hint.
  ///
  /// In en, this message translates to:
  /// **'You will need at least one game file after setup, otherwise the app may not launch.'**
  String get onboardingP4Hint;

  /// No description provided for @onboardingP4Action.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get onboardingP4Action;

  /// No description provided for @onboardingP5Title.
  ///
  /// In en, this message translates to:
  /// **'Create Platform Directories?'**
  String get onboardingP5Title;

  /// No description provided for @onboardingP5Desc.
  ///
  /// In en, this message translates to:
  /// **'Subdirectories for all supported game platforms will be created inside your ROMs folder, each with an auto-generated systeminfo.txt config file. If you skip this, you will need to create these files manually.'**
  String get onboardingP5Desc;

  /// No description provided for @onboardingP5Action.
  ///
  /// In en, this message translates to:
  /// **'Create Now'**
  String get onboardingP5Action;

  /// No description provided for @onboardingP5Skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingP5Skip;

  /// No description provided for @onboardingP6Title.
  ///
  /// In en, this message translates to:
  /// **'All Set!'**
  String get onboardingP6Title;

  /// No description provided for @onboardingP6Desc.
  ///
  /// In en, this message translates to:
  /// **'Pantas is configured and ready to use.'**
  String get onboardingP6Desc;

  /// No description provided for @onboardingP6Hint.
  ///
  /// In en, this message translates to:
  /// **'You still need to install an emulator for each game platform. Some emulators may require additional ROM folder access permissions, otherwise games may not launch.'**
  String get onboardingP6Hint;

  /// No description provided for @onboardingP6Action.
  ///
  /// In en, this message translates to:
  /// **'Start Using'**
  String get onboardingP6Action;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
