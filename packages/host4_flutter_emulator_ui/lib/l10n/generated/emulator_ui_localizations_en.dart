// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'emulator_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class EmulatorUiLocalizationsEn extends EmulatorUiLocalizations {
  EmulatorUiLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuQuickLoad => 'Quick Load';

  @override
  String get menuSaveManager => 'Save Manager';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total used';
  }

  @override
  String get menuQuickSave => 'Quick Save';

  @override
  String get menuQuickSaveSubtitle => 'Overwrite quick save';

  @override
  String get menuSpeed => 'Speed';

  @override
  String get menuExit => 'Exit Game';

  @override
  String get menuContinue => 'Continue';

  @override
  String get menuContinueSubtitle => 'Back to game';

  @override
  String get menuLayout => 'Switch Layout';

  @override
  String get menuKeyLocator => 'Key Position';

  @override
  String get menuPauseLabel => 'Pause Menu';

  @override
  String get saveDeleteTitle => 'Delete save?';

  @override
  String get saveDeleteMessage => 'This cannot be undone.';

  @override
  String get saveCancel => 'Cancel';

  @override
  String get saveDelete => 'Delete';

  @override
  String get saveQuickSection => 'Quick Save';

  @override
  String get saveQuickLabel => 'Quick Save';

  @override
  String get saveLoad => 'Load';

  @override
  String get saveManualSection => 'Manual Save';

  @override
  String saveSlotName(int slot) {
    return 'Save $slot';
  }

  @override
  String get saveSave => 'Save';

  @override
  String get saveOverwrite => 'Overwrite';

  @override
  String get saveTitle => 'Save Manager';

  @override
  String get saveNoQuickSave => 'No quick save yet';

  @override
  String get keyLocatorTitle => 'Adjust virtual button positions';

  @override
  String get keyLocatorInstruction =>
      'Hold and drag virtual buttons to adjust their positions';

  @override
  String get keyLocatorLandscapeHint =>
      'Drag left/right, press Pantas key again to save global layout';

  @override
  String get keyLocatorPortraitHint =>
      'Drag up/down, press Pantas key again to save global layout';

  @override
  String get keyLocatorGamepatchHint =>
      'If using Gamepatch, align with its button positions for better feel';

  @override
  String get layoutTitle => 'Switch Layout';

  @override
  String get layoutSilicone => 'Silicone Pad';

  @override
  String get layoutModernSymmetric => 'Modern Symmetric';

  @override
  String get layoutModernAsymmetric => 'Modern Asymmetric';

  @override
  String get layoutRetroClassic => 'Retro Classic';
}
