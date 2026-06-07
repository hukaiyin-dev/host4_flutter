import Foundation
import VolcEngineRTC

class AiVoiceManager: NSObject {

  // MARK: - 常量
  static let appId = "68230496df1dcd01804db0a9"
  static let appKey = "5054eb5367ec4703bc6763ca78736038"

  // MARK: - 属性
  let roomId: String
  let userId: String

  var rtcEngine: ByteRTCEngine?
  var rtcRoom: ByteRTCRoom?
  var taskId: String?
  var chatbotId: String?
  var connectState: AiConnectState = .connecting
  var isUserVip = false
  var isUserAsk = false
  var eventCallback: (([String: Any]) -> Void)?

  private var isSpeaking = false
  private var isJoinRoom = false
  private var latestConvModel: ConversationStatusMessage?

  // MARK: - 初始化
  init(roomId: String, userId: String) {
    self.roomId = roomId
    self.userId = userId
    super.init()
  }

  // MARK: - 创建引擎并加入房间
  func buildEngineAndJoin() {
    let engineCfg = ByteRTCEngineConfig()
    engineCfg.appID = Self.appId
    engineCfg.parameters = [:]
    rtcEngine = ByteRTCEngine.createRTCEngine(engineCfg, delegate: self)

    guard let engine = rtcEngine else { return }

    let audioConfig = ByteRTCAudioPropertiesConfig()
    audioConfig.enableVad = true
    audioConfig.interval = 200
    engine.enableAudioPropertiesReport(audioConfig)
    engine.startAudioCapture()
    engine.setAudioProfile(.default)
    engine.setPlaybackVolume(100)

    isUserAsk = false
    joinRoom()
  }

  // MARK: - 加入房间
  func joinRoom() {
    guard let engine = rtcEngine else { return }

    let roomID = roomId
    let userID = userId

    rtcRoom = engine.createRTCRoom(roomID)
    rtcRoom?.delegate = self
    rtcRoom?.setUserVisibility(true)

    let userInfo = ByteRTCUserInfo()
    userInfo.userId = userID

    guard let token = AccessToken.generate(roomID: roomID, userID: userID) else {
      print("[AiVoice] ❌ Token 生成失败")
      return
    }

    let roomCfg = ByteRTCRoomConfig()
    roomCfg.isPublishAudio = false
    roomCfg.isPublishVideo = false
    roomCfg.isAutoSubscribeAudio = true
    roomCfg.isAutoSubscribeVideo = false

    rtcRoom?.joinRoom(token, userInfo: userInfo, userVisibility: true, roomConfig: roomCfg)
  }

  // MARK: - 重连
  func reJoinRoom() {
    if isJoinRoom {
      startAgent()
    } else {
      joinRoom()
    }
  }

  // MARK: - 离开房间
  func leaveRoom() {
    rtcRoom?.leave()
    rtcRoom?.destroy()
    rtcRoom = nil
  }

  // MARK: - 开麦/关麦（使用 publishStreamAudio）
  func startTalk() {
    rtcRoom?.publishStreamAudio(true)
    isUserVip = true
  }

  func stopTalk() {
    rtcRoom?.publishStreamAudio(false)
    isUserVip = false
  }

  // MARK: - 音量
  func setVolume(_ level: Int) {
    rtcEngine?.setPlaybackVolume(level)
  }

  // MARK: - 销毁
  func destroy() {
    agentLeave()
    leaveRoom()
    ByteRTCEngine.destroyRTCEngine()
    rtcEngine = nil

    taskId = nil
    chatbotId = nil
    isSpeaking = false
    isUserAsk = false
    isUserVip = false
    isJoinRoom = false
    connectState = .loseConnect
    latestConvModel = nil
  }

  // MARK: - 启动智能体
  func startAgent() {
    guard rtcEngine != nil,
          let roomID = rtcRoom?.getId(),
          !roomID.isEmpty
    else {
      print("[AiVoice] ❌ 引擎未初始化")
      return
    }

    let tid = taskId ?? RtcUtils.generateTaskId()
    taskId = tid
    let botname = chatbotId ?? RtcUtils.generateChatbotId()
    chatbotId = botname

    emitEvent("agentJoin", data: [
      "roomId": roomID,
      "taskId": tid,
      "userId": userId,
      "chatbotId": botname,
    ])
  }

  // MARK: - 退出智能体
  func agentLeave() {
    guard let roomID = rtcRoom?.getId(), let tid = taskId else { return }
    emitEvent("agentLeave", data: ["roomId": roomID, "taskId": tid])
    taskId = nil
    chatbotId = nil
  }

  // MARK: - 事件发送
  func emitEvent(_ type: String, data: [String: Any] = [:]) {
    var event = data
    event["event"] = type
    eventCallback?(event)
  }
}

// MARK: - ByteRTCEngineDelegate
extension AiVoiceManager: ByteRTCEngineDelegate {
  func rtcEngine(_ engine: ByteRTCEngine, onNetworkTypeChanged type: ByteRTCNetworkType) {
    // type 为枚举值，直接比较整数
    if type.rawValue == 0 {
      connectState = .loseConnect
      emitEvent("connectionState", data: ["state": connectState.rawValue])
    }
  }

  func rtcEngine(_ engine: ByteRTCEngine, onConnectionStateChanged state: ByteRTCConnectionState) {
    switch state {
    case .connecting, .reconnecting:
      connectState = .connecting
    case .connected, .reconnected:
      connectState = .connected
    default:
      connectState = .loseConnect
    }
    emitEvent("connectionState", data: ["state": connectState.rawValue])
  }

  func rtcEngine(_ engine: ByteRTCEngine, onLocalAudioPropertiesReport audioPropertiesInfos: [ByteRTCLocalAudioPropertiesInfo]) {
    var speaking = false
    for info in audioPropertiesInfos {
      if info.audioPropertiesInfo.vad == 1 && info.audioPropertiesInfo.linearVolume > 10 {
        speaking = true
      }
    }
    isSpeaking = speaking
    emitEvent("volume", data: [
      "speaking": speaking,
      "volume": audioPropertiesInfos.first?.audioPropertiesInfo.linearVolume ?? 0,
    ])
  }
}

// MARK: - ByteRTCRoomDelegate
extension AiVoiceManager: ByteRTCRoomDelegate {
  func rtcRoom(_ rtcRoom: ByteRTCRoom, onRoomStateChanged roomId: String, withUid uid: String, state: Int, extraInfo: String) {
    if state == 0 {
      isJoinRoom = true
      if taskId == nil { taskId = RtcUtils.generateTaskId() }
      if chatbotId == nil { chatbotId = RtcUtils.generateChatbotId() }
      connectState = .connected
      emitEvent("roomState", data: ["state": "joined", "roomId": roomId, "uid": uid])
      startAgent()
    } else {
      connectState = .loseConnect
      emitEvent("roomState", data: ["state": "failed", "code": state])
    }
  }

  func rtcRoom(_ rtcRoom: ByteRTCRoom, onLeaveRoom stats: ByteRTCRoomStats) {
    // 不做特殊处理
  }

  func onTokenWillExpire(_ rtcRoom: ByteRTCRoom) {
    let roomID = rtcRoom.getId()
    if let token = AccessToken.generate(roomID: roomID, userID: userId) {
      rtcRoom.updateToken(token)
    }
  }

  func rtcRoom(_ rtcRoom: ByteRTCRoom, onRoomBinaryMessageReceived uid: String, message: Data) {
    if let subtitles = SubtitleMsgData.unpack(from: message) {
      let items = SubtitleMsgData.parse(json: subtitles, currentUserId: userId)
      for item in items {
        emitEvent("subtitle", data: [
          "text": item.text,
          "roundId": item.roundId,
          "definite": item.definite,
          "paragraph": item.paragraph,
          "sequence": item.sequence,
          "userId": item.userId,
          "msgType": item.msgType,
        ])
        if item.userId == userId && item.definite {
          isUserAsk = true
        }
        if item.isBotCompleteSentenceNeedsSpecialHandling(botUserId: chatbotId ?? "") && isUserAsk {
          emitEvent("chargeCheck", data: ["roundId": item.roundId, "text": item.text])
        }
        if item.isBotCompleteSentenceAndPlayAudio(botUserId: chatbotId ?? "") {
          emitEvent("playSpecialAudio", data: [:])
        }
      }
      return
    }

    let convStr = ConversationStatusMessage.unpack(from: message)
    if let conv = convStr.flatMap({ ConversationStatusMessage.parse(json: $0) }) {
      latestConvModel = conv
      emitEvent("conversationState", data: [
        "code": conv.stage.code,
        "description": conv.stage.description,
        "taskId": conv.taskId,
        "roundId": conv.roundID,
      ])
      if conv.stage.code == 3 {
        emitEvent("chatState", data: ["state": "interrupt"])
      } else if conv.stage.code == 4 || conv.stage.code == 5 {
        emitEvent("chatState", data: ["state": "normal"])
      }
    }
  }
}
