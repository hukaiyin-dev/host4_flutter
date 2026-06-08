import Foundation

/// AI 智能体 HTTP 请求管理
class AgentRequestManager {
  /// AI 服务基础 URL
  static let baseURL = "https://gamemacro.cn/ai"

  /// 智能体加入房间
  /// - Parameters:
  ///   - boostingTableID: 智能体配置 ID
  ///   - roomID: RTC 房间 ID
  ///   - taskID: 任务 ID
  ///   - userID: 用户 ID
  ///   - botname: 智能体名称（可选）
  ///   - language: 语言代码，如 "zh"
  ///   - completion: 回调（成功/失败）
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
      print("[AgentRequest] ❌ 参数不完整")
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

    post(path: "start_voice_chat", parameters: params) { success, _ in
      if success {
        print("[AgentRequest] ✅ 智能体加入房间成功")
      } else {
        print("[AgentRequest] ❌ 智能体加入房间失败")
      }
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
    post(path: "stop_voice_chat", parameters: params) { success, _ in
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
    post(path: "update_voice_chat", parameters: params) { success, _ in
      completion(success)
    }
  }

  // MARK: - Private

  private static func post(
    path: String,
    parameters: [String: Any],
    completion: @escaping (Bool, Any?) -> Void
  ) {
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

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        print("[AgentRequest] ❌ \(path) 失败: \(error.localizedDescription)")
        DispatchQueue.main.async { completion(false, error) }
        return
      }
      if let httpResponse = response as? HTTPURLResponse {
        print("[AgentRequest] \(path) status: \(httpResponse.statusCode)")
      }
      DispatchQueue.main.async { completion(true, data) }
    }.resume()
  }
}
