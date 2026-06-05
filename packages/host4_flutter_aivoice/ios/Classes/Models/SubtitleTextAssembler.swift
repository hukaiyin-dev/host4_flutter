import Foundation

/// 字幕文本拼接器 — 处理 SubtitleMsgData 并返回完整文本
class SubtitleTextAssembler {
  static let shared = SubtitleTextAssembler()

  // 缓存 key: "userId-roundId"
  private var confirmedTextCache: [String: String] = [:]
  private var tempTextCache: [String: String] = [:]
  private var completeStatusCache: [String: Bool] = [:]
  private var processedMessagesCache: [String: Set<String>] = [:]

  private init() {}

  /// 处理字幕数据，返回当前完整文本
  func assembleText(_ data: SubtitleMsgData) -> String {
    let key = "\(data.userId)-\(data.roundId)"

    // 检查是否已处理（去重）
    if isMessageProcessed(data, forKey: key) {
      let confirmed = confirmedTextCache[key] ?? ""
      let temp = tempTextCache[key] ?? ""
      return confirmed + temp
    }

    markMessageAsProcessed(data, forKey: key)

    var confirmed = confirmedTextCache[key] ?? ""

    if data.definite {
      confirmed += data.text
      confirmedTextCache[key] = confirmed
      tempTextCache.removeValue(forKey: key)

      if data.paragraph {
        completeStatusCache[key] = true
      }
      return confirmed
    } else {
      tempTextCache[key] = data.text
      return confirmed + data.text
    }
  }

  /// 检查消息是否完成
  func isCompleteFor(userId: String, roundId: Int) -> Bool {
    return completeStatusCache["\(userId)-\(roundId)"] ?? false
  }

  /// 清空所有缓存
  func clearCache() {
    confirmedTextCache.removeAll()
    tempTextCache.removeAll()
    completeStatusCache.removeAll()
    processedMessagesCache.removeAll()
  }

  /// 清空指定用户的缓存
  func clearCacheFor(userId: String, roundId: Int) {
    let key = "\(userId)-\(roundId)"
    confirmedTextCache.removeValue(forKey: key)
    tempTextCache.removeValue(forKey: key)
    completeStatusCache.removeValue(forKey: key)
    processedMessagesCache.removeValue(forKey: key)
  }

  // MARK: - Private

  private func messageHash(_ data: SubtitleMsgData) -> String {
    return "\(data.text)_\(data.definite)_\(data.paragraph)"
  }

  private func isMessageProcessed(_ data: SubtitleMsgData, forKey key: String) -> Bool {
    let hash = messageHash(data)
    return processedMessagesCache[key]?.contains(hash) ?? false
  }

  private func markMessageAsProcessed(_ data: SubtitleMsgData, forKey key: String) {
    let hash = messageHash(data)
    if processedMessagesCache[key] == nil {
      processedMessagesCache[key] = Set()
    }
    processedMessagesCache[key]?.insert(hash)
  }
}
