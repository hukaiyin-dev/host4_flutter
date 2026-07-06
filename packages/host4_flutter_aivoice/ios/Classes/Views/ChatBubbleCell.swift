import UIKit

/// 聊天气泡 Cell
class ChatBubbleCell: UITableViewCell {

  private let bubbleView = UIView()
  private let messageLabel = UILabel()
  private var leadingConstraint: NSLayoutConstraint!
  private var trailingConstraint: NSLayoutConstraint!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func setupUI() {
    backgroundColor = .clear
    selectionStyle = .none

    bubbleView.layer.cornerRadius = 12
    bubbleView.clipsToBounds = true
    contentView.addSubview(bubbleView)

    messageLabel.font = .systemFont(ofSize: 14)
    messageLabel.numberOfLines = 0
    messageLabel.textColor = .white
    bubbleView.addSubview(messageLabel)

    bubbleView.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.translatesAutoresizingMaskIntoConstraints = false

    leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
    trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)

    NSLayoutConstraint.activate([
      bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
      bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
      leadingConstraint,
      trailingConstraint,

      messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
      messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 10),
      messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -10),
      messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
    ])
  }

  func configure(text: String, isUser: Bool) {
    messageLabel.text = text

    if isUser {
      // 用户消息：右对齐，绿色
      leadingConstraint.isActive = false
      trailingConstraint.isActive = true
      bubbleView.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 0.40, alpha: 1.0)
    } else {
      // AI 消息：左对齐，半透明灰
      leadingConstraint.isActive = true
      trailingConstraint.isActive = false
      bubbleView.backgroundColor = UIColor(white: 1.0, alpha: 0.15)
    }

    layoutIfNeeded()
  }
}
