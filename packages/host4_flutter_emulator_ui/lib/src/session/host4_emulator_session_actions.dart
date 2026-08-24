abstract class Host4EmulatorSessionActions {
  double get rate;

  Future<void> quickSave();

  Future<void> quickLoad();

  Future<void> deleteQuickSave();

  Future<void> saveSlot(int slot);

  Future<void> loadSlot(int slot);

  Future<void> deleteSlot(int slot);

  Future<void> setRate(double value);

  Future<void> resume();

  Future<void> restart();

  Future<void> exit();
}
