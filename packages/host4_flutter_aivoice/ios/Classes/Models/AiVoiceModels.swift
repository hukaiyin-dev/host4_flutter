import Foundation

// MARK: - AI 语音消息状态
enum AiVoiceMessageState: Int {
  case error      = 0  /// 失败
  case listening  = 1  /// 听
  case thinking   = 2  /// 思考
  case speaking   = 3  /// 说话
  case interrupt  = 4  /// 中断
  case complete   = 5  /// 完成
}

// MARK: - AI 语音聊天状态
enum AiVoiceChatState: Int {
  case connecting  = 0  /// 连接中
  case normal      = 1  /// 连接成功未说话
  case speaking    = 2  /// 用户说话中
  case interrupt   = 3  /// AI 播放中（可打断）
  case reconnect   = 4  /// 点击重新连接
  case notVip      = 5  /// 不是 VIP
}

// MARK: - AI 连接状态
enum AiConnectState: Int {
  case connecting  = 0  /// 连接中
  case connected   = 1  /// 连接成功
  case loseConnect = 2  /// 失去连接
}
