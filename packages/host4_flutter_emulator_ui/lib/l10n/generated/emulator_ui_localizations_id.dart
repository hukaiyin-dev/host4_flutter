// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'emulator_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class EmulatorUiLocalizationsId extends EmulatorUiLocalizations {
  EmulatorUiLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get menuQuickLoad => 'Muat Cepat';

  @override
  String get menuSaveManager => 'Kelola Simpanan';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total terpakai';
  }

  @override
  String get menuQuickSave => 'Simpan Cepat';

  @override
  String get menuQuickSaveSubtitle => 'Timpa simpanan cepat';

  @override
  String get menuSpeed => 'Kecepatan';

  @override
  String get menuExit => 'Keluar Game';

  @override
  String get menuContinue => 'Lanjutkan';

  @override
  String get menuContinueSubtitle => 'Kembali ke game';

  @override
  String get menuLayout => 'Ganti Tata Letak';

  @override
  String get menuKeyLocator => 'Posisi Tombol';

  @override
  String get menuPauseLabel => 'Menu Jeda';

  @override
  String get saveDeleteTitle => 'Hapus simpanan?';

  @override
  String get saveDeleteMessage => 'Tidak dapat dibatalkan.';

  @override
  String get saveCancel => 'Batal';

  @override
  String get saveDelete => 'Hapus';

  @override
  String get saveQuickSection => 'Simpan Cepat';

  @override
  String get saveQuickLabel => 'Simpan Cepat';

  @override
  String get saveLoad => 'Muat';

  @override
  String get saveManualSection => 'Simpan Manual';

  @override
  String saveSlotName(int slot) {
    return 'Simpanan $slot';
  }

  @override
  String get saveSave => 'Simpan';

  @override
  String get saveOverwrite => 'Timpa';

  @override
  String get saveTitle => 'Kelola Simpanan';

  @override
  String get saveNoQuickSave => 'Belum ada simpanan cepat';

  @override
  String get keyLocatorTitle => 'Sesuaikan posisi tombol virtual';

  @override
  String get keyLocatorInstruction =>
      'Tahan dan seret tombol virtual untuk menyesuaikan posisi';

  @override
  String get keyLocatorLandscapeHint =>
      'Seret kiri/kanan, tekan tombol Pantas lagi untuk menyimpan tata letak';

  @override
  String get keyLocatorPortraitHint =>
      'Seret atas/bawah, tekan tombol Pantas lagi untuk menyimpan tata letak';

  @override
  String get keyLocatorGamepatchHint =>
      'Jika menggunakan Gamepatch, sejajarkan dengan posisi tombolnya';

  @override
  String get layoutTitle => 'Ganti Tata Letak';

  @override
  String get layoutSilicone => 'Bantalan Silikon';

  @override
  String get layoutModernSymmetric => 'Modern Simetris';

  @override
  String get layoutModernAsymmetric => 'Modern Asimetris';

  @override
  String get layoutRetroClassic => 'Retro Klasik';
}
