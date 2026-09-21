// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'emulator_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class EmulatorUiLocalizationsZh extends EmulatorUiLocalizations {
  EmulatorUiLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get menuQuickLoad => '快速读档';

  @override
  String get menuSaveManager => '存档管理';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total 已用';
  }

  @override
  String get menuQuickSave => '快速存档';

  @override
  String get menuQuickSaveSubtitle => '覆盖快速存档';

  @override
  String get menuSpeed => '倍速';

  @override
  String get menuExit => '退出游戏';

  @override
  String get menuContinue => '继续游戏';

  @override
  String get menuContinueSubtitle => '返回游戏';

  @override
  String get menuLayout => '切换布局';

  @override
  String get menuKeyLocator => '按键定位';

  @override
  String get menuPauseLabel => '暂停菜单';

  @override
  String get saveDeleteTitle => '删除存档？';

  @override
  String get saveDeleteMessage => '删除后无法恢复。';

  @override
  String get saveCancel => '取消';

  @override
  String get saveDelete => '删除';

  @override
  String get saveQuickSection => '快速存档';

  @override
  String get saveQuickLabel => '快速存档';

  @override
  String get saveLoad => '读取';

  @override
  String get saveManualSection => '手动存档';

  @override
  String saveSlotName(int slot) {
    return '存档 $slot';
  }

  @override
  String get saveSave => '保存';

  @override
  String get saveOverwrite => '覆盖';

  @override
  String get saveTitle => '存档管理';

  @override
  String get saveNoQuickSave => '暂无快速存档';

  @override
  String get keyLocatorTitle => '调整虚拟按键位置';

  @override
  String get keyLocatorInstruction => '按住并拖动虚拟按键，调整至合适的位置';

  @override
  String get keyLocatorLandscapeHint => '支持左右拖动，再次按Pantas键保存全局布局';

  @override
  String get keyLocatorPortraitHint => '支持上下拖动，再次按Pantas键保存全局布局';

  @override
  String get keyLocatorGamepatchHint => '如使用Gamepatch，可与其按键位置对齐，获得更好的按键手感';

  @override
  String get layoutTitle => '切换布局';

  @override
  String get layoutSilicone => '硅胶垫';

  @override
  String get layoutModernSymmetric => '现代对称';

  @override
  String get layoutModernAsymmetric => '现代非对称';

  @override
  String get layoutRetroClassic => '复古传统';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class EmulatorUiLocalizationsZhHant extends EmulatorUiLocalizationsZh {
  EmulatorUiLocalizationsZhHant() : super('zh_Hant');

  @override
  String get menuQuickLoad => '快速讀檔';

  @override
  String get menuSaveManager => '存檔管理';

  @override
  String menuSaveManagerUsed(int used, int total) {
    return '$used/$total 已用';
  }

  @override
  String get menuQuickSave => '快速存檔';

  @override
  String get menuQuickSaveSubtitle => '覆蓋快速存檔';

  @override
  String get menuSpeed => '倍速';

  @override
  String get menuExit => '退出遊戲';

  @override
  String get menuContinue => '繼續遊戲';

  @override
  String get menuContinueSubtitle => '返回遊戲';

  @override
  String get menuLayout => '切換佈局';

  @override
  String get menuKeyLocator => '按鍵定位';

  @override
  String get menuPauseLabel => '暫停選單';

  @override
  String get saveDeleteTitle => '刪除存檔？';

  @override
  String get saveDeleteMessage => '刪除後無法恢復。';

  @override
  String get saveCancel => '取消';

  @override
  String get saveDelete => '刪除';

  @override
  String get saveQuickSection => '快速存檔';

  @override
  String get saveQuickLabel => '快速存檔';

  @override
  String get saveLoad => '讀取';

  @override
  String get saveManualSection => '手動存檔';

  @override
  String saveSlotName(int slot) {
    return '存檔 $slot';
  }

  @override
  String get saveSave => '保存';

  @override
  String get saveOverwrite => '覆蓋';

  @override
  String get saveTitle => '存檔管理';

  @override
  String get saveNoQuickSave => '暫無快速存檔';

  @override
  String get keyLocatorTitle => '調整虛擬按鍵位置';

  @override
  String get keyLocatorInstruction => '按住並拖動虛擬按鍵，調整至合適的位置';

  @override
  String get keyLocatorLandscapeHint => '支持左右拖動，再次按Pantas鍵保存全局佈局';

  @override
  String get keyLocatorPortraitHint => '支持上下拖動，再次按Pantas鍵保存全局佈局';

  @override
  String get keyLocatorGamepatchHint => '如使用Gamepatch，可與其按鍵位置對齊，獲得更好的按鍵手感';

  @override
  String get layoutTitle => '切換佈局';

  @override
  String get layoutSilicone => '矽膠墊';

  @override
  String get layoutModernSymmetric => '現代對稱';

  @override
  String get layoutModernAsymmetric => '現代非對稱';

  @override
  String get layoutRetroClassic => '復古傳統';
}
