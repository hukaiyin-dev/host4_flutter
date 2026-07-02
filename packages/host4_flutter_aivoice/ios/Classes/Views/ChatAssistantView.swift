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
  /// 当前状态消息（仅用于内部工具栏状态更新，不显示在气泡列表）
  private var latestConvMsg: ConversationStatusMessage?

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
    backImgV.backgroundColor = UIColor.black.withAlphaComponent(0.85)
    backImgV.layer.cornerRadius = 16
    backImgV.clipsToBounds = true
    containerView.addSubview(backImgV)

    // 关闭按钮
    closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    closeButton.tintColor = .white
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(closeButton)

    // 全屏/缩小按钮
    fullscreenButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
    fullscreenButton.setImage(UIImage(systemName: "arrow.down.right.and.arrow.up.left"), for: .selected)
    fullscreenButton.tintColor = .white
    fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(fullscreenButton)

    // 音量按钮
    volumeButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
    volumeButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .selected)
    volumeButton.tintColor = .white
    volumeButton.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(volumeButton)

    // AI 标题
    aiChatLab.text = "AI 助手"
    aiChatLab.textColor = .white
    aiChatLab.font = .systemFont(ofSize: 16, weight: .medium)
    aiChatLab.textAlignment = .center
    aiChatLab.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(aiChatLab)

    // 等待动画
    waitView.isHidden = true
    waitView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(waitView)

    // 状态标签
    statusLabel.text = "等待回复..."
    statusLabel.textColor = .lightGray
    statusLabel.font = .systemFont(ofSize: 12)
    statusLabel.textAlignment = .center
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(statusLabel)

    // 聊天界面
    chatView.isHidden = true
    chatView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(chatView)

    // 工具栏
    toolsView.isHidden = true
    toolsView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(toolsView)

    // VIP 标签
    vipLab.textColor = .orange
    vipLab.font = .systemFont(ofSize: 12)
    vipLab.textAlignment = .center
    vipLab.numberOfLines = 0
    vipLab.isHidden = true
    vipLab.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(vipLab)

    // VIP 按钮
    vipBtn.setTitle("解锁无限畅聊", for: .normal)
    vipBtn.setTitleColor(.orange, for: .normal)
    vipBtn.titleLabel?.font = .systemFont(ofSize: 14)
    vipBtn.isHidden = true
    vipBtn.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(vipBtn)
  }

  private func setupLayout() {
    containerView.translatesAutoresizingMaskIntoConstraints = false
    let views = [
      containerView, backImgV, closeButton, fullscreenButton, volumeButton,
      aiChatLab, waitView, statusLabel, chatView, toolsView, vipLab, vipBtn,
    ]
    for v in views {
      v.translatesAutoresizingMaskIntoConstraints = false
    }

    NSLayoutConstraint.activate([
      // containerView 填满 self
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

      // 背景图
      backImgV.topAnchor.constraint(equalTo: containerView.topAnchor),
      backImgV.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      backImgV.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      backImgV.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

      // 关闭按钮：左上角
      closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
      closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
      closeButton.widthAnchor.constraint(equalToConstant: 24),
      closeButton.heightAnchor.constraint(equalToConstant: 24),

      // 全屏按钮：右上角
      fullscreenButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
      fullscreenButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
      fullscreenButton.widthAnchor.constraint(equalToConstant: 24),
      fullscreenButton.heightAnchor.constraint(equalToConstant: 24),

      // 音量按钮：全屏按钮左侧
      volumeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
      volumeButton.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -6),
      volumeButton.widthAnchor.constraint(equalToConstant: 24),
      volumeButton.heightAnchor.constraint(equalToConstant: 24),

      // 标题：顶部居中
      aiChatLab.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      aiChatLab.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      aiChatLab.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 4),
      aiChatLab.trailingAnchor.constraint(lessThanOrEqualTo: volumeButton.leadingAnchor, constant: -4),

      // 工具栏：底部
      toolsView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
      toolsView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
      toolsView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4),
      toolsView.heightAnchor.constraint(equalToConstant: 36),

      // 等待动画：中间
      waitView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      waitView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -20),
      waitView.widthAnchor.constraint(equalToConstant: 120),
      waitView.heightAnchor.constraint(equalToConstant: 120),

      // 状态标签：动画下方
      statusLabel.topAnchor.constraint(equalTo: waitView.bottomAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
      statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

      // 聊天气泡：顶部标题和底部工具栏之间
      chatView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 4),
      chatView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
      chatView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
      chatView.bottomAnchor.constraint(equalTo: toolsView.topAnchor, constant: -4),

      // VIP 标签和按钮
      vipLab.topAnchor.constraint(equalTo: chatView.bottomAnchor, constant: 4),
      vipLab.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
      vipLab.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
      vipBtn.topAnchor.constraint(equalTo: vipLab.bottomAnchor, constant: 4),
      vipBtn.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
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

  // MARK: - 切换展开/缩小

  /// 切换展开/缩小状态（带动画）
  func toggleExpanded() {
    let centerPoint = center
    let willExpand = !isExpanded
    let newSize: CGSize
    if willExpand {
      let screenW = UIScreen.main.bounds.width
      let screenH = UIScreen.main.bounds.height
      newSize = CGSize(width: min(360, screenW - 32), height: min(520, screenH - 120))
    } else {
      newSize = CGSize(width: 200, height: 60)
    }

    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
      self.frame = CGRect(origin: .zero, size: newSize)
      self.center = centerPoint
    } completion: { _ in
      self.isExpanded = willExpand
      self.chatView.isHidden = !willExpand
      self.toolsView.isHidden = !willExpand
      self.waitView.isHidden = willExpand
      self.statusLabel.isHidden = willExpand
    }
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
      // 状态消息仅用于更新工具栏状态，不显示在气泡列表中
      self?.latestConvMsg = convMsg
    }
  }

  func updateSubvMessage(_ subvMsg: SubtitleMsgData) {
    // 特殊字符替换（对齐 OC 版 isBotCompleteSentenceAndPlayAudio 逻辑）
    if subvMsg.isBotCompleteSentenceAndPlayAudio(botUserId: AiVoiceManager.shared.chatbotId ?? "") {
      subvMsg.text = NSLocalizedString("ReplySpecial", comment: "")
      AiVoiceManager.shared.playSpecialAudio()
    }

    // 空文本过滤
    if subvMsg.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return
    }

    chatView.addMessage(subvMsg)

    // 对齐 OC：更新 lastMsg 用于缩小窗口显示
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isThinking = false
      self.lastMsg = SubtitleTextAssembler.shared.assembleText(subvMsg)
      // 缩小状态时显示最新字幕在 aiChatLab
      if !self.isExpanded {
        self.aiChatLab.text = self.lastMsg
      }
    }
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
