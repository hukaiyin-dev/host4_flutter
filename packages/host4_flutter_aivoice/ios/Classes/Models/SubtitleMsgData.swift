import Foundation

/// subv 消息 - 字幕数据
class SubtitleMsgData {
  var text: String      /// 可变，用于特殊字符替换
  let language: String
  let userId: String
  let sequence: Int
  let roundId: Int
  let definite: Bool    /// 完整分句
  let paragraph: Bool   /// 段落结束
  var msgType: Int      /// 0=用户消息, 1=机器人消息

  init(text: String, language: String, userId: String,
       sequence: Int, roundId: Int, definite: Bool,
       paragraph: Bool, msgType: Int) {
    self.text = text
    self.language = language
    self.userId = userId
    self.sequence = sequence
    self.roundId = roundId
    self.definite = definite
    self.paragraph = paragraph
    self.msgType = msgType
  }

  /// 拆包校验：从二进制数据中提取 subv JSON 字符串
  /// magic number = 0x73756276 ("subv")
  static func unpack(from data: Data) -> String? {
    let headerSize = 8
    guard data.count >= headerSize else { return nil }

    let magic = data.withUnsafeBytes { ptr in
      ptr.loadUnaligned(fromByteOffset: 0, as: UInt32.self).bigEndian
    }
    guard magic == 0x7375_6276 else { return nil }

    let length = data.withUnsafeBytes { ptr in
      ptr.loadUnaligned(fromByteOffset: 4, as: UInt32.self).bigEndian
    }
    guard data.count - headerSize == length else { return nil }

    if length == 0 { return "" }
    return String(data: data.subdata(in: headerSize..<data.count), encoding: .utf8)
  }

  /// 解析 JSON 字符串为 [SubtitleMsgData]
  /// JSON 格式: {"data": [{text, language, userId, sequence, roundId, definite, paragraph}, ...]}
  static func parse(json: String, currentUserId: String) -> [SubtitleMsgData] {
    guard let jsonData = json.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
          let items = dict["data"] as? [[String: Any]]
    else { return [] }

    return items.map { item in
      let userId = item["userId"] as? String ?? ""
      let msgType = (userId == currentUserId) ? 0 : 1

      return SubtitleMsgData(
        text: item["text"] as? String ?? "",
        language: item["language"] as? String ?? "",
        userId: userId,
        sequence: item["sequence"] as? Int ?? 0,
        roundId: item["roundId"] as? Int ?? 0,
        definite: item["definite"] as? Bool ?? false,
        paragraph: item["paragraph"] as? Bool ?? false,
        msgType: msgType
      )
    }
  }
}
