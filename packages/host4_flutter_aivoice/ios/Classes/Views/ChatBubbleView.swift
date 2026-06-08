import UIKit

/// 聊天气泡视图
class ChatBubbleView: UIView {

  weak var delegate: ChatBubbleViewDelegate?
  private var messages: [SubtitleMsgData] = []
  private var convMessage: ConversationStatusMessage?

  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.backgroundColor = .clear
    tv.separatorStyle = .none
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tv.dataSource = self
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

  func addMessage(_ msg: SubtitleMsgData) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.messages.append(msg)
      self.tableView.reloadData()
      let idx = IndexPath(row: self.messages.count - 1, section: 0)
      self.tableView.scrollToRow(at: idx, at: .bottom, animated: true)
    }
  }

  func updateConvMessage(_ conv: ConversationStatusMessage) {
    DispatchQueue.main.async { [weak self] in
      self?.convMessage = conv
    }
  }

  func clear() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.messages.removeAll()
      self.tableView.reloadData()
    }
  }
}

extension ChatBubbleView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let msg = messages[indexPath.row]
    cell.textLabel?.text = msg.text
    cell.textLabel?.font = .systemFont(ofSize: 14)
    cell.textLabel?.numberOfLines = 0
    cell.backgroundColor = .clear
    cell.textLabel?.textColor = .white
    return cell
  }
}

protocol ChatBubbleViewDelegate: AnyObject {
  func chatBubbleViewDidScroll(_ view: ChatBubbleView)
}
