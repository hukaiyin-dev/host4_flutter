import UIKit

/// AI 悬浮窗/聊天窗状态
enum AiFloatingViewState {
  case floating    // 悬浮球
  case chatMinimized  // 聊天窗缩小
  case chatExpanded   // 聊天窗展开
}

/// AI 视图管理器（单例）
/// 管理悬浮球和聊天窗的显示/隐藏/状态切换
class AiViewManager: NSObject {

  static let shared = AiViewManager()

  /// 当前状态
  var floatState: AiFloatingViewState = .floating

  /// 兼容 iOS 13+ 的 keyWindow
  private var currentKeyWindow: UIWindow? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    } else {
      return UIApplication.shared.keyWindow
    }
  }

  private override init() {
    super.init()
  }

  /// 显示/隐藏 AI 悬浮窗
  /// - Parameter show: true=显示, false=销毁
  func showFloatWindow(_ show: Bool) {
    print("[AiView] showFloatWindow: \(show), state: \(floatState)")

    let targetVC = UIApplication.shared.topViewController(base: nil)

    if !show {
      XHFloatWindow.xh_destroyWindow()
      if ChatAssistantView.shared.isShowing {
        ChatAssistantView.shared.hide()
      }
      AiVoiceManager.shared.destructionRTCEngine()
      return
    }

    switch floatState {
    case .floating:
      showFloatingBall(target: targetVC)
    case .chatMinimized, .chatExpanded:
      showChatView()
    }
  }

  /// 显示悬浮球
  private func showFloatingBall(target: UIViewController?) {
    if XHFloatWindow.xh_isShowing() { return }

    XHFloatWindow.xh_addWindowOnTarget(target ?? UIViewController()) { [weak self] in
      guard let self = self else { return }
      if self.isPushNothing() {
        self.pushController(0)
      } else {
        let frame = XHFloatWindow.xh_getCurrentFrame()
        XHFloatWindow.xh_destroyWindow()
        self.playAnimation(from: frame)
      }
    }

    // 根据历史状态设置大小
    let isShrunk = XHFloatWindow.xh_getSavedShrunkState()
    let floatWidth = isShrunk ? kShrunkSize : kNormalSize
    XHFloatWindow.xh_setWindowSize(floatWidth)
    XHFloatWindow.xh_setBackgroundImage("AINotClick", for: .normal)

    let screenW = UIScreen.main.bounds.width
    let screenH = UIScreen.main.bounds.height

    if screenH > screenW {
      // 竖屏
      let minW = min(screenW, screenH)
      XHFloatWindow.xh_setInitialPosition(CGPoint(
        x: (minW - floatWidth) / 2,
        y: screenH - 100 * kCoefi - floatWidth / 2
      ))
    } else {
      if isShrunk {
        XHFloatWindow.xh_setInitialPosition(CGPoint(
          x: max(screenW, screenH) - floatWidth,
          y: 65 * kCoefi
        ))
      }
    }
  }

  /// 播放帧动画（点击悬浮球后的展开动画）
  private func playAnimation(from frame: CGRect) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      // 帧动画: 使用 "思考状态-出现_" + 124 帧 png
      let animView = FrameAnimationView(
        imagePrefix: "思考状态-出现_",
        startIndex: 0,
        count: 124,
        numberFormat: "%05d",
        extension: "png"
      )
      animView.frameRate = 40
      animView.animationMode = .once

      guard let window = self.currentKeyWindow else { return }
      window.addSubview(animView)

      let center = CGPoint(
        x: frame.origin.x + frame.size.width / 2,
        y: frame.origin.y + frame.size.height / 2
      )

      animView.animate(
        fromCenter: center,
        toSize: CGSize(width: 100 * kCoefi, height: 100 * kCoefi),
        duration: 3,
        damping: 3,
        autoPlay: true,
        completion: { [weak self] in
          self?.showFloatWindow(false)
          animView.removeFromSuperview()
          self?.floatState = .chatMinimized
          self?.showChatView()
        }
      )
    }
  }

  /// 显示聊天界面
  func showChatView() {
    AiVoiceManager.shared.buildRTCEngine()
    ChatAssistantView.shared.delegate = self

    switch floatState {
    case .chatMinimized:
      ChatAssistantView.shared.showMinimizedAtScreen()
    case .chatExpanded:
      ChatAssistantView.shared.showExpandedAtScreen()
    default:
      break
    }
  }

  /// 需要登录/VIP 页面时触发的回调（由外部宿主 App 处理页面跳转）
  var onNeedPushLogin: (() -> Void)?
  var onNeedPushVip: (() -> Void)?

  /// 跳转页面
  func pushController(_ type: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.showFloatWindow(true)

      if type == 0 {
        self.onNeedPushLogin?()
      } else if type == 1 {
        self.onNeedPushVip?()
      }
    }
  }

  /// 是否需要拦截点击跳转（如未登录状态）
  /// 外部可通过此回调返回是否拦截
  var onCheckShouldBlockTap: (() -> Bool)?

  func isPushNothing() -> Bool {
    return onCheckShouldBlockTap?() ?? false
  }
}

// MARK: - ChatAssistantViewDelegate
extension AiViewManager: ChatAssistantViewDelegate {
  func chatAssistantViewCloseButtonTapped(_ view: ChatAssistantView) {
    showFloatWindow(false)
    ChatAssistantView.destroy()
    AiVoiceManager.shared.destructionRTCEngine()
    floatState = .floating

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.showFloatWindow(true)
    }
  }

  func chatAssistantViewVolumeButtonTapped(_ view: ChatAssistantView, isSec: Bool) {
    AiVoiceManager.shared.switchVoiceVolume(!isSec)
  }

  func chatAssistantViewFullscreenButtonTapped(_ view: ChatAssistantView) {
    // 切换展开/缩小
  }

  func chatAssistantViewVipButtonTapped(_ view: ChatAssistantView) {
    pushController(1)
  }
}

// MARK: - Constants
let kShrunkSize: CGFloat = 60
let kNormalSize: CGFloat = 80
let kCoefi: CGFloat = UIScreen.main.bounds.width / 375.0
