import Foundation

// MARK: - RTC 权限枚举
enum RTCPrivilege: Int16 {
  case publishStream      = 0  /// 发布流
  case publishAudioStream = 1  /// 发布音频流（内部）
  case publishVideoStream = 2  /// 发布视频流（内部）
  case publishDataStream  = 3  /// 发布数据流（内部）
  case subscribeStream    = 4  /// 订阅流
}

/// 火山引擎 RTC Token 生成器
class AccessToken {
  static let version = "001"
  static let versionLength = 3
  static let appIDLength = 24

  var appID: String
  var appKey: String
  var roomID: String
  var userID: String
  var issuedAt: Int32
  var expireAt: Int32
  var nonce: Int32
  var privileges: [Int: Int] = [:]
  var signature: Data?

  init(appID: String, appKey: String, roomID: String, userID: String) {
    self.appID = appID
    self.appKey = appKey
    self.roomID = roomID
    self.userID = userID
    issuedAt = Int32(RtcUtils.timestamp())
    nonce = Int32(RtcUtils.randomInt())
    expireAt = 0
  }

  /// 生成 RTC Token（自包含 appId + appKey）
  static func generate(roomID: String, userID: String) -> String? {
    let appID = "68230496df1dcd01804db0a9"
    let appKey = "5054eb5367ec4703bc6763ca78736038"

    let token = AccessToken(appID: appID, appKey: appKey,
                            roomID: roomID, userID: userID)
    token.setExpire(time: Int32(RtcUtils.timestamp()) + 3600)
    token.addPrivilege(.subscribeStream, expire: 0)
    token.addPrivilege(.publishStream, expire: Int32(RtcUtils.timestamp()) + 3600)

    return token.serialize()
  }

  func addPrivilege(_ privilege: RTCPrivilege, expire: Int32) {
    privileges[Int(privilege.rawValue)] = Int(expire)
    if privilege == .publishStream {
      privileges[Int(RTCPrivilege.publishAudioStream.rawValue)] = Int(expire)
      privileges[Int(RTCPrivilege.publishVideoStream.rawValue)] = Int(expire)
      privileges[Int(RTCPrivilege.publishDataStream.rawValue)] = Int(expire)
    }
  }

  func setExpire(time: Int32) {
    expireAt = time
  }

  func packMsg() -> Data {
    let buf = ByteBuf()
    buf.putInt(nonce)
         .putInt(issuedAt)
         .putInt(expireAt)
         .putString(roomID)
         .putString(userID)
         .putIntMap(privileges)
    return buf.bytes
  }

  func serialize() -> String? {
    let msg = packMsg()
    signature = RtcUtils.hmacSha256(key: appKey, message: msg)

    let buf = ByteBuf()
    buf.putBytes(msg)
    if let sig = signature { buf.putBytes(sig) }

    let encoded = RtcUtils.base64Encode(buf.bytes)
    return "\(Self.version)\(appID)\(encoded)"
  }

  func verify(key: String) -> Bool {
    if expireAt > 0, Int32(RtcUtils.timestamp()) > expireAt { return false }
    appKey = key
    guard let sig = signature else { return false }
    let newSig = RtcUtils.hmacSha256(key: appKey, message: packMsg())
    return sig == newSig
  }

  static func parse(from tokenString: String) -> AccessToken {
    let token = AccessToken(appID: "", appKey: "", roomID: "", userID: "")
    guard tokenString.count > versionLength + appIDLength else { return token }

    let ver = String(tokenString.prefix(versionLength))
    guard ver == version else { return token }

    let appIDStart = tokenString.index(tokenString.startIndex, offsetBy: versionLength)
    let appIDEnd = tokenString.index(appIDStart, offsetBy: appIDLength)
    token.appID = String(tokenString[appIDStart..<appIDEnd])

    let encoded = String(tokenString[appIDEnd...])
    guard let content = RtcUtils.base64Decode(encoded) else { return token }

    let buf = ByteBuf(data: content)
    let msg = buf.readBytes()
    token.signature = buf.readBytes()

    let msgBuf = ByteBuf(data: msg)
    token.nonce = msgBuf.readInt()
    token.issuedAt = msgBuf.readInt()
    token.expireAt = msgBuf.readInt()
    token.roomID = msgBuf.readString()
    token.userID = msgBuf.readString()
    token.privileges = msgBuf.readIntMap()

    return token
  }
}

extension AccessToken: CustomStringConvertible {
  var description: String {
    """
    AccessToken{
      appID='\(appID)',
      roomID='\(roomID)',
      userID='\(userID)',
      issuedAt=\(issuedAt),
      expireAt=\(expireAt),
      nonce=\(nonce),
      privileges=\(privileges)
    }
    """
  }
}
