import UIKit

/// 聊天工具栏状态
enum ChatToolsState {
  case connecting  // 连接中
  case normal      // 正常
  case speaking    // 说话中
  case interrupt   // 可打断
  case reconnect   // 重连
  case notVip      // 非 VIP
}

/// 聊天工具视图
class ChatToolsView: UIView {

  /// 音量按钮（含状态）
  lazy var volumeButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
    btn.setImage(UIImage(systemName: "speaker.slash.fill"), for: .selected)
    btn.tintColor = .white
    btn.addTarget(self, action: #selector(volumeTapped), for: .touchUpInside)
    return btn
  }()

  /// 麦克风按钮
  lazy var micButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    btn.setImage(UIImage(systemName: "mic.slash.fill"), for: .selected)
    btn.tintColor = .white
    btn.addTarget(self, action: #selector(micTapped), for: .touchUpInside)
    return btn
  }()

  /// 关闭按钮
  lazy var closeButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.setImage(UIImage(systemName: "xmark"), for: .normal)
    btn.tintColor = .white
    btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    return btn
  }()

  /// 全屏按钮
  lazy var fullscreenButton: UIButton = {
    let btn = UIButton(type: .custom)
    btn.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
    btn.tintColor = .white
    btn.addTarget(self, action: #selector(fullscreenTapped), for: .touchUpInside)
    return btn
  }()

  var onVolumeTapped: ((Bool) -> Void)?
  var onMicTapped: ((Bool) -> Void)?
  var onCloseTapped: (() -> Void)?
  var onFullscreenTapped: (() -> Void)?

  private var currentState: ChatToolsState = .normal

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func setupUI() {
    backgroundColor = UIColor.black.withAlphaComponent(0.3)
    layer.cornerRadius = 12

    let stack = UIStackView(arrangedSubviews: [
      volumeButton, micButton, fullscreenButton, closeButton
    ])
    stack.axis = .horizontal
    stack.distribution = .equalSpacing
    stack.spacing = 20
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
    ])
  }

  /// 更新 UI 状态
  func updateState(_ state: ChatToolsState) {
    currentState = state
    switch state {
    case .connecting:
      micButton.isEnabled = false
    case .normal:
      micButton.isEnabled = true
      micButton.isSelected = false
    case .speaking:
      micButton.isEnabled = true
      micButton.isSelected = true
    case .interrupt:
      break
    case .reconnect:
      micButton.isEnabled = false
    case .notVip:
      micButton.isEnabled = false
    }
  }

  @objc private func volumeTapped() {
    volumeButton.isSelected.toggle()
    onVolumeTapped?(volumeButton.isSelected)
  }

  @objc private func micTapped() {
    micButton.isSelected.toggle()
    onMicTapped?(micButton.isSelected)
  }

  @objc private func closeTapped() {
    onCloseTapped?()
  }

  @objc private func fullscreenTapped() {
    onFullscreenTapped?()
  }
}
