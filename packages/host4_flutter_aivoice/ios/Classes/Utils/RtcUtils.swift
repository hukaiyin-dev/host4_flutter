import Foundation
import CommonCrypto

struct RtcUtils {

  /// 生成随机整数（Int32 安全范围）
  static func randomInt() -> Int {
    return Int(arc4random_uniform(UInt32(Int32.max)))
  }

  /// 当前时间戳（秒）
  static func timestamp() -> Int {
    return Int(Date().timeIntervalSince1970)
  }

  /// HMAC-SHA256 签名
  static func hmacSha256(key: String, message: Data) -> Data {
    let keyBytes = [UInt8](key.utf8)
    var hmacResult = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    message.withUnsafeBytes { msgBytes in
      CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
             keyBytes, keyBytes.count,
             msgBytes.baseAddress, msgBytes.count,
             &hmacResult)
    }
    return Data(hmacResult)
  }

  /// Base64 编码
  static func base64Encode(_ data: Data) -> String {
    return data.base64EncodedString()
  }

  /// Base64 解码
  static func base64Decode(_ string: String) -> Data? {
    return Data(base64Encoded: string)
  }

  /// 生成房间 ID
  static func generateRoomId() -> String {
    let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    return "room_\(uuid.prefix(8))"
  }

  /// 生成用户 ID
  static func generateUserId() -> String {
    return "user_\(Int(arc4random_uniform(10000)))"
  }

  /// 生成任务 ID
  static func generateTaskId() -> String {
    return "task_\(Int(arc4random_uniform(10000)))"
  }

  /// 生成智能体 ID
  static func generateChatbotId() -> String {
    return "chatbot_\(Int(arc4random_uniform(10000)))"
  }
}
