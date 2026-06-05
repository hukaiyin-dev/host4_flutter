import Foundation

// MARK: - 句子类型枚举
enum SubtitleSentenceType: Int {
  case incomplete   = 0  /// 不完整句子
  case complete     = 1  /// 正常完整句子
  case empty        = 2  /// 完整但内容为空
  case specialSymbol = 3 /// 完整但只有特殊符号
  case paragraphEnd = 4  /// 段落结束
}

// MARK: - SubtitleMsgData 验证扩展
extension SubtitleMsgData {

  /// 是否为机器人消息
  func isBotMessage(_ botUserId: String) -> Bool {
    return userId == botUserId
  }

  /// 是否为完整句子
  var isCompleteSentence: Bool {
    return definite
  }

  /// 是否为段落结束
  var isParagraphEnd: Bool {
    return paragraph
  }

  /// 文本是否为空或无效
  var isEmptyOrNil: Bool {
    return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  /// 是否为特殊符号（~）
  var isSpecialSymbol: Bool {
    return text.trimmingCharacters(in: .whitespacesAndNewlines) == "~"
  }

  /// 是否需要特殊处理
  var needsSpecialHandling: Bool {
    return isSpecialSymbol
  }

  /// 判断机器人的完整句子是否需要扣费
  func isBotCompleteSentenceNeedsSpecialHandling(botUserId: String) -> Bool {
    guard isBotMessage(botUserId) else { return false }

    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    // 特殊字符不扣费
    if trimmed == "~" { return false }
    // 不是完整段落不扣费
    guard paragraph else { return false }
    return true
  }

  /// 判断机器人完整句子是否需要播放音频（特殊内容）
  func isBotCompleteSentenceAndPlayAudio(botUserId: String) -> Bool {
    guard isBotMessage(botUserId) else { return false }
    guard isCompleteSentence else { return false }
    return needsSpecialHandling
  }

  /// 获取句子类型
  var sentenceType: SubtitleSentenceType {
    if !isCompleteSentence { return .incomplete }
    if isParagraphEnd { return .paragraphEnd }
    if isEmptyOrNil { return .empty }
    if isSpecialSymbol { return .specialSymbol }
    return .complete
  }
}
