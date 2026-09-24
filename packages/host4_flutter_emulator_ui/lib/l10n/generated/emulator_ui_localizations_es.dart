// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'emulator_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class EmulatorUiLocalizationsEs extends EmulatorUiLocalizations {
  EmulatorUiLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get menuQuickLoad => 'Carga rápida';

  @override
  String get menuSaveManager => 'Gestor de guardado';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total usados';
  }

  @override
  String get menuQuickSave => 'Guardado rápido';

  @override
  String get menuQuickSaveSubtitle => 'Sobrescribir guardado rápido';

  @override
  String get menuSpeed => 'Velocidad';

  @override
  String get menuExit => 'Salir del juego';

  @override
  String get menuContinue => 'Continuar';

  @override
  String get menuContinueSubtitle => 'Volver al juego';

  @override
  String get menuLayout => 'Cambiar diseño';

  @override
  String get menuKeyLocator => 'Posición de teclas';

  @override
  String get menuPauseLabel => 'Menú de pausa';

  @override
  String get saveDeleteTitle => '¿Eliminar guardado?';

  @override
  String get saveDeleteMessage => 'Esto no se puede deshacer.';

  @override
  String get saveCancel => 'Cancelar';

  @override
  String get saveDelete => 'Eliminar';

  @override
  String get saveQuickSection => 'Guardado rápido';

  @override
  String get saveQuickLabel => 'Guardado rápido';

  @override
  String get saveLoad => 'Cargar';

  @override
  String get saveManualSection => 'Guardado manual';

  @override
  String saveSlotName(int slot) {
    return 'Guardado $slot';
  }

  @override
  String get saveSave => 'Guardar';

  @override
  String get saveOverwrite => 'Sobrescribir';

  @override
  String get saveTitle => 'Gestor de guardado';

  @override
  String get saveNoQuickSave => 'Sin guardado rápido';

  @override
  String get keyLocatorTitle => 'Ajustar posiciones de botones';

  @override
  String get keyLocatorInstruction =>
      'Mantén y arrastra los botones virtuales para ajustar su posición';

  @override
  String get keyLocatorLandscapeHint =>
      'Arrastra izquierda/derecha, presiona Pantas para guardar el diseño';

  @override
  String get keyLocatorPortraitHint =>
      'Arrastra arriba/abajo, presiona Pantas para guardar el diseño';

  @override
  String get keyLocatorGamepatchHint =>
      'Si usas Gamepatch, alinea con sus botones para mejor sensación';

  @override
  String get layoutTitle => 'Cambiar diseño';

  @override
  String get layoutSilicone => 'Almohadilla de silicona';

  @override
  String get layoutModernSymmetric => 'Moderno simétrico';

  @override
  String get layoutModernAsymmetric => 'Moderno asimétrico';

  @override
  String get layoutRetroClassic => 'Retro clásico';
}
