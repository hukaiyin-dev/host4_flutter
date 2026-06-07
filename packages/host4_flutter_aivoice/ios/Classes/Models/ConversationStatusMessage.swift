import Foundation

/// conv 消息 - 智能体状态
struct Stage {
  let code: Int
  let description: String
}

struct ErrorDetail {
  let code: Int
  let reason: String
}

/// 智能体状态消息（conv 协议）
class ConversationStatusMessage {
  let taskId: String
  let userID: String
  let roundID: Int64
  let eventTime: Int64
  let stage: Stage
  let errorInfo: ErrorDetail?
  let hasErrorInfo: Bool

  private init(taskId: String, userID: String, roundID: Int64,
               eventTime: Int64, stage: Stage,
               errorInfo: ErrorDetail?) {
    self.taskId = taskId
    self.userID = userID
    self.roundID = roundID
    self.eventTime = eventTime
    self.stage = stage
    self.errorInfo = errorInfo
    self.hasErrorInfo = errorInfo != nil
  }

  /// 拆包校验：从二进制数据中提取 conv JSON 字符串
  /// magic number = 0x636F6E76 ("conv")
  static func unpack(from data: Data) -> String? {
    let headerSize = 8
    guard data.count >= headerSize else { return nil }

    let magic = data.withUnsafeBytes { ptr in
      ptr.loadUnaligned(fromByteOffset: 0, as: UInt32.self).bigEndian
    }
    guard magic == 0x636F_6E76 else { return nil }

    let length = data.withUnsafeBytes { ptr in
      ptr.loadUnaligned(fromByteOffset: 4, as: UInt32.self).bigEndian
    }
    guard data.count - headerSize == length else { return nil }

    if length == 0 { return "" }
    return String(data: data.subdata(in: headerSize..<data.count), encoding: .utf8)
  }

  /// 解析 JSON 字符串为 ConversationStatusMessage
  static func parse(json: String) -> ConversationStatusMessage? {
    guard let jsonData = json.data(using: .utf8),
          let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    else { return nil }

    let stageDict = dict["Stage"] as? [String: Any]
    let stage = Stage(
      code: stageDict?["Code"] as? Int ?? 0,
      description: stageDict?["Description"] as? String ?? ""
    )

    var errorInfo: ErrorDetail? = nil
    if let errorDict = dict["ErrorInfo"] as? [String: Any],
       !(errorDict is NSNull) {
      errorInfo = ErrorDetail(
        code: errorDict["ErrorCode"] as? Int ?? 0,
        reason: errorDict["Reason"] as? String ?? ""
      )
    }

    return ConversationStatusMessage(
      taskId: dict["TaskId"] as? String ?? "",
      userID: dict["UserID"] as? String ?? "",
      roundID: (dict["RoundID"] as? Int64) ?? 0,
      eventTime: (dict["EventTime"] as? Int64) ?? 0,
      stage: stage,
      errorInfo: errorInfo
    )
  }
}
