import Foundation
import VolcEngineRTC
import AVFoundation

/// AI 语音管理（单例）
class AiVoiceManager: NSObject {

  static let shared = AiVoiceManager()
  static let appId = "68230496df1dcd01804db0a9"
  static let appKey = "5054eb5367ec4703bc6763ca78736038"

  // MARK: - 属性
  var rtcEngine: ByteRTCEngine?
  var rtcRoom: ByteRTCRoom?
  var connectState: AiConnectState = .connecting {
    didSet {
      let chatState: AiVoiceChatState
      switch connectState {
      case .connecting:    chatState = .connecting
      case .loseConnect:   chatState = .reconnect
      default:             chatState = .normal
      }
      ChatAssistantView.shared.updateToolWithChatState(chatState)
    }
  }
  var isUserVip = false
  var isUserAsk = false
  var roomId: String?
  var taskId: String?
  var userId: String?
  var chatbotId: String? {
    didSet {
      ChatAssistantView.shared.updateChatTitle(chatbotId ?? "")
    }
  }
  var boostingTableID = ""

  var isSpeaking: Bool = false {
    didSet {
      if isSpeaking {
        ChatAssistantView.shared.updateToolWithChatState(.speaking)
      } else {
        if latestConvModel?.stage.code == 3 { return }
        ChatAssistantView.shared.updateToolWithChatState(.normal)
      }
    }
  }
  var latestConvModel: ConversationStatusMessage?
  var isJoinRoom = false

  var eventCallback: (([String: Any]) -> Void)?

  private override init() {
    super.init()
  }

  // MARK: - 创建引擎
  func buildRTCEngine() {
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
    engine.stopVideoCapture()

    isUserAsk = false
    joinRoom()
  }

  // MARK: - 销毁引擎
  func destructionRTCEngine() {
    agentLeave()
    leaveRoom()
    ByteRTCEngine.destroyRTCEngine()
    rtcEngine = nil

    userId = nil
    taskId = nil
    roomId = nil
    chatbotId = nil

    isSpeaking = false
    isUserAsk = false
    isUserVip = false
    isJoinRoom = false
    connectState = .loseConnect
    latestConvModel = nil
  }

  // MARK: - 加入房间
  func joinRoom() {
    guard let engine = rtcEngine else { return }

    let rid = roomId ?? RtcUtils.generateRoomId()
    roomId = rid
    rtcRoom = engine.createRTCRoom(rid)
    rtcRoom?.delegate = self
    rtcRoom?.setUserVisibility(true)

    let uid = userId ?? RtcUtils.generateUserId()
    userId = uid

    let userInfo = ByteRTCUserInfo()
    userInfo.userId = uid

    guard let token = AccessToken.generate(roomID: rid, userID: uid) else {
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

  // MARK: - 音量控制
  func switchVoiceVolume(_ open: Bool) {
    guard let engine = rtcEngine else { return }
    print("[AiVoice] \(open ? "开启" : "关闭")音量")
    engine.setPlaybackVolume(open ? 100 : 0)
  }

  // MARK: - 麦克风控制
  func switchAudioCapture(_ isOpen: Bool) {
    guard rtcEngine != nil, rtcRoom != nil else {
      print("[AiVoice] ❌ 引擎或房间未初始化")
      return
    }
    if isUserVip == isOpen {
      print("[AiVoice] ℹ️ 麦克风状态已相同，跳过")
      return
    }
    isUserVip = isOpen

    if isOpen {
      print("[AiVoice] ✅ 开启麦克风")
      rtcRoom?.publishStreamAudio(true)
      ChatAssistantView.shared.updateToolWithChatState(.normal)
    } else {
      print("[AiVoice] ✅ 关闭麦克风")
      rtcRoom?.publishStreamAudio(false)
      ChatAssistantView.shared.updateToolWithChatState(.notVip)
    }
  }

  // MARK: - 启动智能体
  func startAgent() {
    guard rtcEngine != nil, let rid = roomId, !rid.isEmpty,
          let uid = userId, !uid.isEmpty, !boostingTableID.isEmpty else {
      print("[AiVoice] ❌ 参数不完整")
      return
    }

    if taskId == nil { taskId = RtcUtils.generateTaskId() }
    if chatbotId == nil { chatbotId = RtcUtils.generateChatbotId() }

    let tid = taskId!
    let botname = chatbotId!

    ChatAssistantView.shared.updateToolWithChatState(.notVip)

    let lang = NSLocale.current.languageCode ?? "zh"
    AgentRequestManager.agentJoinRoom(
      boostingTableID: boostingTableID,
      roomID: rid,
      taskID: tid,
      userID: uid,
      botname: botname,
      language: lang
    ) { [weak self] success in
      if success {
        print("[AiVoice] ✅ 智能体加入成功")
        self?.getVipUseInfo(0)
      } else {
        print("[AiVoice] ❌ 智能体加入失败")
      }
    }
  }

  // MARK: - 退出智能体
  func agentLeave() {
    guard let rid = roomId, let tid = taskId else { return }
    AgentRequestManager.agentLeaveRoom(roomID: rid, taskID: tid) { _ in }
    roomId = nil
    taskId = nil
    userId = nil
    chatbotId = nil
  }

  // MARK: - VIP 检查
  func getVipUseInfo(_ type: Int) {
    // 实际项目中调后端接口
    // 这里简化处理，默认有权限
    switchAudioCapture(true)
    ChatAssistantView.shared.updateVipTitle(nil)
  }

  func checkVipDeduction(_ subvModel: SubtitleMsgData) {
    if subvModel.userId == userId, subvModel.definite {
      isUserAsk = true
    }
    if subvModel.isBotCompleteSentenceNeedsSpecialHandling(botUserId: chatbotId ?? ""), isUserAsk {
      // TODO: 上报扣费
      getVipUseInfo(1)
    }
  }

  // MARK: - 播放特殊音频
  func playSpecialAudio() {
    let lang = NSLocale.current.languageCode ?? "en"
    let audioName: String
    if lang.hasPrefix("zh") {
      audioName = "illegal_game"
    } else if lang.hasPrefix("ja") {
      audioName = "illegal_game_ja"
    } else {
      audioName = "illegal_game_en"
    }
    WavAudioPlayer.play(audioName: audioName)
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
    if type.rawValue == 0 {
      connectState = .loseConnect
    }
  }

  func rtcEngine(_ engine: ByteRTCEngine, onConnectionStateChanged state: ByteRTCConnectionState) {
    switch state {
    case .connecting, .reconnecting: connectState = .connecting
    case .connected, .reconnected:   connectState = .connected
    default:                         connectState = .loseConnect
    }
  }

  func rtcEngine(_ engine: ByteRTCEngine, onLocalAudioPropertiesReport infos: [ByteRTCLocalAudioPropertiesInfo]) {
    var speaking = false
    for info in infos {
      if info.audioPropertiesInfo.vad == 1, info.audioPropertiesInfo.linearVolume > 10 {
        speaking = true
      }
    }
    isSpeaking = speaking
  }
}

// MARK: - ByteRTCRoomDelegate
extension AiVoiceManager: ByteRTCRoomDelegate {
  func rtcRoom(_ rtcRoom: ByteRTCRoom, onRoomStateChanged roomId: String, withUid uid: String, state: Int, extraInfo: String) {
    if state == 0 {
      isJoinRoom = true
      if taskId == nil { taskId = RtcUtils.generateTaskId() }
      if self.roomId == nil || self.roomId != roomId { self.roomId = roomId }
      if self.userId == nil || self.userId != uid { self.userId = uid }
      if chatbotId == nil { chatbotId = RtcUtils.generateChatbotId() }
      startAgent()
    } else {
      connectState = .loseConnect
    }
  }

  func rtcRoom(_ rtcRoom: ByteRTCRoom, onLeaveRoom stats: ByteRTCRoomStats) {}

  func onTokenWillExpire(_ rtcRoom: ByteRTCRoom) {
    guard let token = AccessToken.generate(roomID: rtcRoom.getId(), userID: userId ?? "") else { return }
    rtcRoom.updateToken(token)
  }

  func rtcRoom(_ rtcRoom: ByteRTCRoom, onRoomBinaryMessageReceived uid: String, message: Data) {
    if let subtitles = SubtitleMsgData.unpack(from: message) {
      let items = SubtitleMsgData.parse(json: subtitles, currentUserId: userId ?? "")
      for item in items {
        checkVipDeduction(item)
        ChatAssistantView.shared.updateSubvMessage(item)
      }
      return
    }

    if let convStr = ConversationStatusMessage.unpack(from: message),
       let conv = ConversationStatusMessage.parse(json: convStr) {
      latestConvModel = conv
      ChatAssistantView.shared.updateConvMessage(conv)

      if conv.stage.code == 3 {
        ChatAssistantView.shared.updateToolWithChatState(.interrupt)
      } else if conv.stage.code == 4 || conv.stage.code == 5 {
        ChatAssistantView.shared.updateToolWithChatState(.normal)
      }
    }
  }
}
