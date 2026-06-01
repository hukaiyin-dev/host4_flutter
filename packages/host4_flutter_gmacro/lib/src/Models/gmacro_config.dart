class GmacroConfig {
  const GmacroConfig({
    this.service = 'FF00',
    this.commandCharacteristic = 'FF01',
    this.dataCharacteristic = 'FF02',
    this.otaService = 'FF10',
    this.otaCommandCharacteristic = 'FF11',
    this.otaDataCharacteristic = 'FF12',
    this.responseTimeout = 60,
    this.messageInterval = 0.09,
    this.otaPacketInterval = 0.05,
    this.profile = 0,
  });

  /// 数据服务 UUID
  final String service;

  /// 命令特征 UUID
  final String commandCharacteristic;

  /// 数据特征 UUID
  final String dataCharacteristic;

  /// OTA 服务 UUID
  final String otaService;

  /// OTA 命令特征 UUID
  final String otaCommandCharacteristic;

  /// OTA 数据特征 UUID
  final String otaDataCharacteristic;

  /// 响应超时（秒）
  final int responseTimeout;

  /// 多条消息之间的发送间隔（秒）
  final double messageInterval;

  /// OTA 单包发送间隔（秒）
  final double otaPacketInterval;

  /// 协议 profile
  final int profile;

  Map<String, Object?> toMap() => {
    'service': service,
    'commandCharacteristic': commandCharacteristic,
    'dataCharacteristic': dataCharacteristic,
    'otaService': otaService,
    'otaCommandCharacteristic': otaCommandCharacteristic,
    'otaDataCharacteristic': otaDataCharacteristic,
    'responseTimeout': responseTimeout,
    'messageInterval': messageInterval,
    'otaPacketInterval': otaPacketInterval,
    'profile': profile,
  };
}
