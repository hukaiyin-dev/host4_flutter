import UIKit

// MARK: - 代理协议
protocol ChatAssistantViewDelegate: AnyObject {
  func chatAssistantViewCloseButtonTapped(_ view: ChatAssistantView)
  func chatAssistantViewVolumeButtonTapped(_ view: ChatAssistantView, isSec: Bool)
  func chatAssistantViewFullscreenButtonTapped(_ view: ChatAssistantView)
  func chatAssistantViewVipButtonTapped(_ view: ChatAssistantView)
}

/// AI 对话助手视图（单例）
/// 支持缩小/展开两种状态，包含聊天气泡、工具栏、状态显示
class ChatAssistantView: UIView {

  // MARK: - 单例
  static var shared: ChatAssistantView = {
    let instance = ChatAssistantView()
    return instance
  }()

  static func destroy() {
    let view = shared
    if let delegate = view.delegate {
      delegate.chatAssistantViewWillDestroy(view)
    }

    view.hideAnimated(true)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      view.removeFromSuperview()
      if let delegate = view.delegate {
        delegate.chatAssistantViewDidDestroy(view)
      }
    }
  }

  static var isInstanceCreated: Bool {
    // 简单检查是否初始化过
    return shared.isShowing
  }

  // MARK: - 属性
  weak var delegate: ChatAssistantViewDelegate?

  private(set) var isShowing = false
  private(set) var isExpanded = false {
    didSet {
      if isExpanded {
        AiViewManager.shared.floatState = .chatExpanded
      } else {
        AiViewManager.shared.floatState = .chatMinimized
      }
    }
  }
  private var isThinking = false
  private var lastMsg: String?

  // MARK: - UI 元素
  private let containerView = UIView()
  private let backImgV = UIImageView()
  private let closeButton = UIButton(type: .custom)
  private let fullscreenButton = UIButton(type: .custom)
  private let volumeButton = UIButton(type: .custom)
  private let aiChatLab = UILabel()
  private let waitView = FrameAnimationView(
    imagePrefix: "思考状态-出现_", startIndex: 0, count: 124,
    numberFormat: "%05d", extension: "png"
  )
  private let statusLabel = UILabel()
  private let chatView = ChatBubbleView()
  private let toolsView = ChatToolsView()
  private let vipLab = UILabel()
  private let vipBtn = UIButton(type: .custom)

  // MARK: - 初始化
  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func commonInit() {
    backgroundColor = UIColor.black.withAlphaComponent(0.85)
    layer.cornerRadius = 16
    clipsToBounds = true
    isHidden = true

    setupContainerView()
    setupSubviews()
    setupLayout()
    setupActions()
  }

  private func setupContainerView() {
    containerView.backgroundColor = .clear
    addSubview(containerView)
  }

  private func setupSubviews() {
    // 背景图
    backImgV.contentMode = .scaleAspectFill
    containerView.addSubview(backImgV)

    // 关闭按钮
    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    closeButton.tintColor = .white
    containerView.addSubview(closeButton)

    // 全屏按钮
    fullscreenButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
    fullscreenButton.tintColor = .white
    containerView.addSubview(fullscreenButton)

    // 音量按钮
    volumeButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
    volumeButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .selected)
    volumeButton.tintColor = .white
    containerView.addSubview(volumeButton)

    // AI 标题
    aiChatLab.text = "AI 助手"
    aiChatLab.textColor = .white
    aiChatLab.font = .systemFont(ofSize: 16, weight: .medium)
    aiChatLab.textAlignment = .center
    containerView.addSubview(aiChatLab)

    // 等待动画
    waitView.isHidden = true
    containerView.addSubview(waitView)

    // 状态标签
    statusLabel.text = "等待回复..."
    statusLabel.textColor = .lightGray
    statusLabel.font = .systemFont(ofSize: 12)
    statusLabel.textAlignment = .center
    containerView.addSubview(statusLabel)

    // 聊天界面
    chatView.isHidden = true
    containerView.addSubview(chatView)

    // 工具栏
    toolsView.isHidden = true
    containerView.addSubview(toolsView)

    // VIP 标签
    vipLab.textColor = .orange
    vipLab.font = .systemFont(ofSize: 12)
    vipLab.textAlignment = .center
    vipLab.numberOfLines = 0
    containerView.addSubview(vipLab)

    // VIP 按钮
    vipBtn.setTitle("解锁无限畅聊", for: .normal)
    vipBtn.setTitleColor(.orange, for: .normal)
    vipBtn.titleLabel?.font = .systemFont(ofSize: 14)
    containerView.addSubview(vipBtn)
  }

  private func setupLayout() {
    containerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  private func setupActions() {
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    fullscreenButton.addTarget(self, action: #selector(fullscreenTapped), for: .touchUpInside)
    volumeButton.addTarget(self, action: #selector(volumeTapped), for: .touchUpInside)
    vipBtn.addTarget(self, action: #selector(vipTapped), for: .touchUpInside)
  }

  // MARK: - Actions
  @objc private func closeTapped() {
    delegate?.chatAssistantViewCloseButtonTapped(self)
  }

  @objc private func fullscreenTapped() {
    delegate?.chatAssistantViewFullscreenButtonTapped(self)
  }

  @objc private func volumeTapped() {
    volumeButton.isSelected.toggle()
    delegate?.chatAssistantViewVolumeButtonTapped(self, isSec: volumeButton.isSelected)
  }

  @objc private func vipTapped() {
    delegate?.chatAssistantViewVipButtonTapped(self)
  }

  // MARK: - 显示方法

  /// 显示缩小状态
  func showMinimizedAtPoint(_ point: CGPoint) {
    let size = CGSize(width: 200, height: 60)
    frame = CGRect(origin: .zero, size: size)
    center = point
    show()
    isExpanded = false
  }

  /// 显示缩小状态（GameMacro 默认位置）
  func showMinimizedAtScreen() {
    let size = CGSize(width: 200, height: 60)
    let centerX = UIScreen.main.bounds.width / 2
    let centerY = UIScreen.main.bounds.height - 100
    frame = CGRect(x: centerX - size.width / 2, y: centerY - size.height / 2,
                   width: size.width, height: size.height)
    show()
    isExpanded = false
  }

  /// 显示展开状态
  func showExpandedAtPoint(_ point: CGPoint) {
    let size = CGSize(width: 320, height: 480)
    frame = CGRect(origin: .zero, size: size)
    center = point
    show()
    isExpanded = true
  }

  /// 显示展开状态（GameMacro 默认位置）
  func showExpandedAtScreen() {
    let screenW = UIScreen.main.bounds.width
    let screenH = UIScreen.main.bounds.height
    let width: CGFloat = min(360, screenW - 32)
    let height: CGFloat = min(520, screenH - 120)
    let x = (screenW - width) / 2
    let y = (screenH - height) / 2
    frame = CGRect(x: x, y: y, width: width, height: height)
    show()
    isExpanded = true
  }

  private func show() {
    guard let window = UIApplication.shared.keyWindow else { return }
    window.addSubview(self)
    isHidden = false
    isShowing = true
    transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    alpha = 0
    UIView.animate(withDuration: 0.3) {
      self.transform = .identity
      self.alpha = 1
    }
  }

  func hide() {
    hideAnimated(true)
  }

  func hideAnimated(_ animated: Bool) {
    if animated {
      UIView.animate(withDuration: 0.25) {
        self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        self.alpha = 0
      } completion: { _ in
        self.isHidden = true
        self.isShowing = false
        self.removeFromSuperview()
      }
    } else {
      isHidden = true
      isShowing = false
      removeFromSuperview()
    }
  }

  // MARK: - 内容更新

  func updateToolWithChatState(_ chatState: AiVoiceChatState) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      let state: ChatToolsState
      switch chatState {
      case .connecting: state = .connecting
      case .normal:     state = .normal
      case .speaking:   state = .speaking
      case .interrupt:  state = .interrupt
      case .reconnect:  state = .reconnect
      case .notVip:     state = .notVip
      }
      self.toolsView.updateState(state)
    }
  }

  func updateConvMessage(_ convMsg: ConversationStatusMessage) {
    DispatchQueue.main.async { [weak self] in
      self?.chatView.updateConvMessage(convMsg)
    }
  }

  func updateSubvMessage(_ subvMsg: SubtitleMsgData) {
    chatView.addMessage(subvMsg) // addMessage 内部已处理主线程
  }

  func updateChatTitle(_ title: String) {
    DispatchQueue.main.async { [weak self] in
      self?.aiChatLab.text = title
    }
  }

  func updateVipTitle(_ title: String?) {
    DispatchQueue.main.async { [weak self] in
      self?.vipLab.text = title
      self?.vipBtn.isHidden = title != nil
      self?.vipLab.isHidden = title == nil
    }
  }
}

// MARK: - ChatAssistantViewDelegate 默认实现
extension ChatAssistantViewDelegate {
  func chatAssistantViewWillDestroy(_ view: ChatAssistantView) {}
  func chatAssistantViewDidDestroy(_ view: ChatAssistantView) {}
  func chatAssistantViewCloseButtonTapped(_ view: ChatAssistantView) {}
  func chatAssistantViewVolumeButtonTapped(_ view: ChatAssistantView, isSec: Bool) {}
  func chatAssistantViewFullscreenButtonTapped(_ view: ChatAssistantView) {}
  func chatAssistantViewVipButtonTapped(_ view: ChatAssistantView) {}
}
