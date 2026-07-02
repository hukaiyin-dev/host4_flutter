import UIKit

/// 聊天气泡视图
class ChatBubbleView: UIView {

  weak var delegate: ChatBubbleViewDelegate?

  /// 消息列表（文本 + 是否用户）
  private var messages: [(text: String, isUser: Bool)] = []

  /// "roundId-msgType" → texts index，用于消息去重合并
  private var roundIndexMap: [String: Int] = [:]

  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.backgroundColor = .clear
    tv.separatorStyle = .none
    tv.register(ChatBubbleCell.self, forCellReuseIdentifier: "ChatBubbleCell")
    tv.dataSource = self
    tv.delegate = self
    tv.rowHeight = UITableView.automaticDimension
    tv.estimatedRowHeight = 44
    return tv
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(tableView)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    tableView.frame = bounds
  }

  /// 添加/更新字幕消息（支持去重和拼接）
  func addMessage(_ msg: SubtitleMsgData) {
    let fullText = SubtitleTextAssembler.shared.assembleText(msg)
    let key = "\(msg.roundId)-\(msg.msgType)"
    let isUser = msg.msgType == 0

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      if let existingIndex = self.roundIndexMap[key] {
        // 更新已有消息
        self.messages[existingIndex] = (text: fullText, isUser: isUser)
        self.tableView.reloadRows(at: [IndexPath(row: existingIndex, section: 0)], with: .none)
      } else {
        // 新消息
        let index = self.messages.count
        self.messages.append((text: fullText, isUser: isUser))
        self.roundIndexMap[key] = index
        self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .fade)
      }

      if !self.messages.isEmpty {
        let last = IndexPath(row: self.messages.count - 1, section: 0)
        self.tableView.scrollToRow(at: last, at: .bottom, animated: true)
      }
    }
  }

  func clear() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.messages.removeAll()
      self.roundIndexMap.removeAll()
      self.tableView.reloadData()
    }
  }
}

extension ChatBubbleView: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChatBubbleCell", for: indexPath) as! ChatBubbleCell
    let msg = messages[indexPath.row]
    cell.configure(text: msg.text, isUser: msg.isUser)
    return cell
  }
}

protocol ChatBubbleViewDelegate: AnyObject {
  func chatBubbleViewDidScroll(_ view: ChatBubbleView)
}
