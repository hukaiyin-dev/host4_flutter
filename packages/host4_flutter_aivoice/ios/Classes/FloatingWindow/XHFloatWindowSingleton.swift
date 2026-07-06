import UIKit

/// 悬浮窗单例管理类
class XHFloatWindowSingleton: NSObject {

  static let shared = XHFloatWindowSingleton()

  var floatVC = XHFloatWindowController()
  var floatWindowCallBack: (() -> Void)?
  var isShowing = false
  var savedShrunkState = false

  private override init() {
    super.init()
  }

  func xh_isShrunk() -> Bool { savedShrunkState }

  func xh_setShrunk(_ shrunk: Bool) {
    savedShrunkState = shrunk
    floatVC.setShrunk(shrunk)
  }

  func xh_addWindowOnTarget(_ target: Any, onClick callback: (() -> Void)?) {
    floatWindowCallBack = callback
    floatVC.show(callback: { [weak self] in
      self?.floatWindowCallBack?()
    })
    floatVC.createButton(size: kNormalSize)
    isShowing = true
  }

  func xh_setWindowSize(_ size: CGFloat) {
    floatVC.setButtonSize(size)
  }

  func xh_setHideWindow(_ hide: Bool) {
    if hide {
      floatVC.hide()
      isShowing = false
    } else {
      floatVC.show(callback: floatWindowCallBack ?? {})
      isShowing = true
    }
  }

  func xh_setBackgroundImage(_ imageName: String?, for state: UIControl.State) {
    guard let name = imageName else { return }
    let image = pluginImage(name)
    floatVC.setButtonImage(image, for: state)
  }

  func xh_setInitialPosition(_ position: CGPoint) {
    floatVC.setButtonPosition(position)
  }

  func xh_getCurrentFrame() -> CGRect {
    return floatVC.getButtonFrame()
  }

  func xh_destroyWindow() {
    floatVC.destroy()
    isShowing = false
  }

  func xh_rebuildWindowOnTarget(_ target: Any, onClick callback: (() -> Void)?) {
    xh_destroyWindow()
    xh_addWindowOnTarget(target, onClick: callback)
  }
}
