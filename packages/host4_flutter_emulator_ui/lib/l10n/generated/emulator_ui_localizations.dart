import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'emulator_ui_localizations_en.dart';
import 'emulator_ui_localizations_es.dart';
import 'emulator_ui_localizations_id.dart';
import 'emulator_ui_localizations_ja.dart';
import 'emulator_ui_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of EmulatorUiLocalizations
/// returned by `EmulatorUiLocalizations.of(context)`.
///
/// Applications need to include `EmulatorUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/emulator_ui_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: EmulatorUiLocalizations.localizationsDelegates,
///   supportedLocales: EmulatorUiLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the EmulatorUiLocalizations.supportedLocales
/// property.
abstract class EmulatorUiLocalizations {
  EmulatorUiLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static EmulatorUiLocalizations of(BuildContext context) {
    return Localizations.of<EmulatorUiLocalizations>(
      context,
      EmulatorUiLocalizations,
    )!;
  }

  static const LocalizationsDelegate<EmulatorUiLocalizations> delegate =
      _EmulatorUiLocalizationsDelegate();

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
    Locale('es'),
    Locale('id'),
    Locale('ja'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @menuQuickLoad.
  ///
  /// In zh, this message translates to:
  /// **'快速读档'**
  String get menuQuickLoad;

  /// No description provided for @menuSaveManager.
  ///
  /// In zh, this message translates to:
  /// **'存档管理'**
  String get menuSaveManager;

  /// No description provided for @menuSaveManagerUsed.
  ///
  /// In zh, this message translates to:
  /// **'{used}/{total} 已用'**
  String menuSaveManagerUsed(int used, int total);

  /// No description provided for @menuQuickSave.
  ///
  /// In zh, this message translates to:
  /// **'快速存档'**
  String get menuQuickSave;

  /// No description provided for @menuQuickSaveSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'覆盖快速存档'**
  String get menuQuickSaveSubtitle;

  /// No description provided for @menuSpeed.
  ///
  /// In zh, this message translates to:
  /// **'倍速'**
  String get menuSpeed;

  /// No description provided for @menuExit.
  ///
  /// In zh, this message translates to:
  /// **'退出游戏'**
  String get menuExit;

  /// No description provided for @menuContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续游戏'**
  String get menuContinue;

  /// No description provided for @menuContinueSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'返回游戏'**
  String get menuContinueSubtitle;

  /// No description provided for @menuLayout.
  ///
  /// In zh, this message translates to:
  /// **'切换布局'**
  String get menuLayout;

  /// No description provided for @menuKeyLocator.
  ///
  /// In zh, this message translates to:
  /// **'按键定位'**
  String get menuKeyLocator;

  /// No description provided for @menuPauseLabel.
  ///
  /// In zh, this message translates to:
  /// **'暂停菜单'**
  String get menuPauseLabel;

  /// No description provided for @saveDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除存档？'**
  String get saveDeleteTitle;

  /// No description provided for @saveDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复。'**
  String get saveDeleteMessage;

  /// No description provided for @saveCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get saveCancel;

  /// No description provided for @saveDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get saveDelete;

  /// No description provided for @saveQuickSection.
  ///
  /// In zh, this message translates to:
  /// **'快速存档'**
  String get saveQuickSection;

  /// No description provided for @saveQuickLabel.
  ///
  /// In zh, this message translates to:
  /// **'快速存档'**
  String get saveQuickLabel;

  /// No description provided for @saveLoad.
  ///
  /// In zh, this message translates to:
  /// **'读取'**
  String get saveLoad;

  /// No description provided for @saveManualSection.
  ///
  /// In zh, this message translates to:
  /// **'手动存档'**
  String get saveManualSection;

  /// No description provided for @saveSlotName.
  ///
  /// In zh, this message translates to:
  /// **'存档 {slot}'**
  String saveSlotName(int slot);

  /// No description provided for @saveSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get saveSave;

  /// No description provided for @saveOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖'**
  String get saveOverwrite;

  /// No description provided for @saveTitle.
  ///
  /// In zh, this message translates to:
  /// **'存档管理'**
  String get saveTitle;

  /// No description provided for @saveNoQuickSave.
  ///
  /// In zh, this message translates to:
  /// **'暂无快速存档'**
  String get saveNoQuickSave;

  /// No description provided for @keyLocatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'调整虚拟按键位置'**
  String get keyLocatorTitle;

  /// No description provided for @keyLocatorInstruction.
  ///
  /// In zh, this message translates to:
  /// **'按住并拖动虚拟按键，调整至合适的位置'**
  String get keyLocatorInstruction;

  /// No description provided for @keyLocatorLandscapeHint.
  ///
  /// In zh, this message translates to:
  /// **'支持左右拖动，再次按Pantas键保存全局布局'**
  String get keyLocatorLandscapeHint;

  /// No description provided for @keyLocatorPortraitHint.
  ///
  /// In zh, this message translates to:
  /// **'支持上下拖动，再次按Pantas键保存全局布局'**
  String get keyLocatorPortraitHint;

  /// No description provided for @keyLocatorGamepatchHint.
  ///
  /// In zh, this message translates to:
  /// **'如使用Gamepatch，可与其按键位置对齐，获得更好的按键手感'**
  String get keyLocatorGamepatchHint;

  /// No description provided for @layoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'切换布局'**
  String get layoutTitle;

  /// No description provided for @layoutSilicone.
  ///
  /// In zh, this message translates to:
  /// **'硅胶垫'**
  String get layoutSilicone;

  /// No description provided for @layoutModernSymmetric.
  ///
  /// In zh, this message translates to:
  /// **'现代对称'**
  String get layoutModernSymmetric;

  /// No description provided for @layoutModernAsymmetric.
  ///
  /// In zh, this message translates to:
  /// **'现代非对称'**
  String get layoutModernAsymmetric;

  /// No description provided for @layoutRetroClassic.
  ///
  /// In zh, this message translates to:
  /// **'复古传统'**
  String get layoutRetroClassic;
}

class _EmulatorUiLocalizationsDelegate
    extends LocalizationsDelegate<EmulatorUiLocalizations> {
  const _EmulatorUiLocalizationsDelegate();

  @override
  Future<EmulatorUiLocalizations> load(Locale locale) {
    return SynchronousFuture<EmulatorUiLocalizations>(
      lookupEmulatorUiLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'id', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_EmulatorUiLocalizationsDelegate old) => false;
}

EmulatorUiLocalizations lookupEmulatorUiLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return EmulatorUiLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return EmulatorUiLocalizationsEn();
    case 'es':
      return EmulatorUiLocalizationsEs();
    case 'id':
      return EmulatorUiLocalizationsId();
    case 'ja':
      return EmulatorUiLocalizationsJa();
    case 'zh':
      return EmulatorUiLocalizationsZh();
  }

  throw FlutterError(
    'EmulatorUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
