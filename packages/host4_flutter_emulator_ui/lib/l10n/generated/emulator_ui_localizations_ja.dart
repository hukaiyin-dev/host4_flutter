// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'emulator_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class EmulatorUiLocalizationsJa extends EmulatorUiLocalizations {
  EmulatorUiLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get menuQuickLoad => 'クイックロード';

  @override
  String get menuSaveManager => 'セーブ管理';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total 使用済';
  }

  @override
  String get menuQuickSave => 'クイックセーブ';

  @override
  String get menuQuickSaveSubtitle => 'クイックセーブを上書き';

  @override
  String get menuSpeed => '倍速';

  @override
  String get menuExit => 'ゲーム終了';

  @override
  String get menuContinue => 'ゲームを続ける';

  @override
  String get menuContinueSubtitle => 'ゲームに戻る';

  @override
  String get menuLayout => 'レイアウト切替';

  @override
  String get menuKeyLocator => 'キー位置調整';

  @override
  String get menuPauseLabel => 'ポーズメニュー';

  @override
  String get saveDeleteTitle => 'セーブを削除しますか？';

  @override
  String get saveDeleteMessage => '削除すると元に戻せません。';

  @override
  String get saveCancel => 'キャンセル';

  @override
  String get saveDelete => '削除';

  @override
  String get saveQuickSection => 'クイックセーブ';

  @override
  String get saveQuickLabel => 'クイックセーブ';

  @override
  String get saveLoad => 'ロード';

  @override
  String get saveManualSection => '手動セーブ';

  @override
  String saveSlotName(int slot) {
    return 'セーブ $slot';
  }

  @override
  String get saveSave => '保存';

  @override
  String get saveOverwrite => '上書き';

  @override
  String get saveTitle => 'セーブ管理';

  @override
  String get saveNoQuickSave => 'クイックセーブなし';

  @override
  String get keyLocatorTitle => '仮想ボタンの位置を調整';

  @override
  String get keyLocatorInstruction => '仮想ボタンを長押しして適切な位置にドラッグします';

  @override
  String get keyLocatorLandscapeHint => '左右にドラッグ可能、Pantasキーを再度押すとグローバルレイアウトを保存';

  @override
  String get keyLocatorPortraitHint => '上下にドラッグ可能、Pantasキーを再度押すとグローバルレイアウトを保存';

  @override
  String get keyLocatorGamepatchHint => 'Gamepatchをお使いの場合、ボタン位置を合わせると操作感が向上します';

  @override
  String get layoutTitle => 'レイアウト切替';

  @override
  String get layoutSilicone => 'シリコンパッド';

  @override
  String get layoutModernSymmetric => 'モダン対称';

  @override
  String get layoutModernAsymmetric => 'モダン非対称';

  @override
  String get layoutRetroClassic => 'レトロクラシック';
}
