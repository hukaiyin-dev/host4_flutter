import UIKit

/// 悬浮窗控制器
class XHFloatWindowController: NSObject {

  var floatWindowCallBack: (() -> Void)?
  var button: XHDraggableButton?
  var savedShrunkState = false

  private var floatingView: UIView?
  private var isShowing = false

  /// 获取当前 keyWindow（兼容 iOS 13+ Scene API）
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

  /// 在 keyWindow 上创建悬浮按钮
  func show(callback: @escaping () -> Void) {
    floatWindowCallBack = callback
    guard let window = currentKeyWindow else {
      print("[FloatWindow] ❌ 找不到 keyWindow")
      return
    }
    guard floatingView == nil else {
      print("[FloatWindow] ℹ️ 悬浮窗已存在，跳过创建")
      return
    }

    let container = UIView(frame: UIScreen.main.bounds)
    container.isUserInteractionEnabled = false
    window.addSubview(container)
    floatingView = container
    isShowing = true
    print("[FloatWindow] ✅ 悬浮窗容器已创建")
  }

  func hide() {
    floatingView?.removeFromSuperview()
    floatingView = nil
    isShowing = false
  }

  func createButton(size: CGFloat) {
    guard let container = floatingView else {
      print("[FloatWindow] ❌ 容器不存在，无法创建按钮")
      return
    }

    let btn = XHDraggableButton(type: .custom)
    let btnSize = max(size, 44) // 最小 44pt
    btn.frame = CGRect(x: 0, y: 0, width: btnSize, height: btnSize)
    btn.layer.cornerRadius = btnSize / 2
    btn.clipsToBounds = true

    // 先尝试加载图片，失败则用默认背景
    if let icon = UIImage(named: "AINotClick") {
      print("[FloatWindow] ✅ 加载 AINotClick 图片成功")
      btn.setImage(icon, for: .normal)
      btn.backgroundColor = .clear
    } else {
      print("[FloatWindow] ℹ️ 使用默认蓝色背景")
      btn.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
      let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
      let micImage = UIImage(systemName: "waveform.circle.fill", withConfiguration: config)?
        .withTintColor(.white, renderingMode: .alwaysOriginal)
      btn.setImage(micImage, for: .normal)
    }

    btn.layer.shadowColor = UIColor.black.cgColor
    btn.layer.shadowOffset = CGSize(width: 0, height: 2)
    btn.layer.shadowRadius = 6
    btn.layer.shadowOpacity = 0.3
    btn.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

    container.addSubview(btn)
    button = btn
    container.isUserInteractionEnabled = true
    print("[FloatWindow] ✅ 悬浮按钮已创建, size: \(btnSize)")
  }

  @objc private func buttonTapped() {
    print("[FloatWindow] 👆 悬浮按钮被点击")
    floatWindowCallBack?()
  }

  func setButtonImage(_ image: UIImage?, for state: UIControl.State) {
    button?.setImage(image, for: state)
    if image != nil {
      button?.backgroundColor = .clear
    }
  }

  func setButtonSize(_ size: CGFloat) {
    let btnSize = max(size, 44)
    button?.frame.size = CGSize(width: btnSize, height: btnSize)
    button?.layer.cornerRadius = btnSize / 2
  }

  func setButtonPosition(_ position: CGPoint) {
    button?.center = position
  }

  func getButtonFrame() -> CGRect {
    return button?.frame ?? .zero
  }

  func setShrunk(_ shrunk: Bool) {
    savedShrunkState = shrunk
  }

  func xh_isShrunk() -> Bool { savedShrunkState }

  func destroy() {
    button?.removeFromSuperview()
    button = nil
    floatingView?.removeFromSuperview()
    floatingView = nil
    isShowing = false
    print("[FloatWindow] 🗑️ 悬浮窗已销毁")
  }
}
