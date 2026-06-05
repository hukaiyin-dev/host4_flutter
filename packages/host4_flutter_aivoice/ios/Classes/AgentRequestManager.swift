import Foundation

/// AI 智能体 HTTP 请求管理
/// 注意：VIP/支付接口建议放在 Flutter 侧通过 Dio 调用，这里只处理核心智能体控制
class AgentRequestManager {
  /// 配置 AI 服务的基础 URL（由 Flutter 传入）
  static var baseURL = ""

  /// 智能体加入房间
  static func agentJoinRoom(
    boostingTableID: String,
    roomID: String,
    taskID: String,
    userID: String,
    botname: String?,
    language: String,
    completion: @escaping (Bool) -> Void
  ) {
    guard !boostingTableID.isEmpty, !roomID.isEmpty, !taskID.isEmpty, !userID.isEmpty else {
      completion(false)
      return
    }

    var params: [String: Any] = [
      "BoostingTableID": boostingTableID,
      "RoomID": roomID,
      "TaskID": taskID,
      "TargetUserID": userID,
      "SystemLanguage": language,
    ]
    if let botname = botname, !botname.isEmpty {
      params["Botname"] = botname
    }

    post(path: "startVoiceChat", parameters: params) { success, _ in
      completion(success)
    }
  }

  /// 智能体退出房间
  static func agentLeaveRoom(
    roomID: String,
    taskID: String,
    completion: @escaping (Bool) -> Void
  ) {
    guard !roomID.isEmpty, !taskID.isEmpty else {
      completion(false)
      return
    }
    let params: [String: Any] = ["RoomID": roomID, "TaskID": taskID]
    post(path: "stopVoiceChat", parameters: params) { success, _ in
      completion(success)
    }
  }

  /// 智能体更新
  static func agentUpdateRoom(
    roomID: String,
    taskID: String,
    command: String,
    completion: @escaping (Bool) -> Void
  ) {
    guard !roomID.isEmpty, !taskID.isEmpty, !command.isEmpty else {
      completion(false)
      return
    }
    let params: [String: Any] = ["RoomID": roomID, "TaskID": taskID, "Command": command]
    post(path: "updateVoiceChat", parameters: params) { success, _ in
      completion(success)
    }
  }

  // MARK: - Private

  private static func post(
    path: String,
    parameters: [String: Any],
    completion: @escaping (Bool, Any?) -> Void
  ) {
    guard !baseURL.isEmpty else {
      print("[AgentRequest] ⚠️ baseURL 未设置")
      completion(false, nil)
      return
    }

    guard let url = URL(string: "\(baseURL)/\(path)") else {
      completion(false, nil)
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 20

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    } catch {
      completion(false, nil)
      return
    }

    URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        print("[AgentRequest] ❌ \(path) 失败: \(error.localizedDescription)")
        DispatchQueue.main.async { completion(false, error) }
        return
      }
      DispatchQueue.main.async { completion(true, data) }
    }.resume()
  }
}
