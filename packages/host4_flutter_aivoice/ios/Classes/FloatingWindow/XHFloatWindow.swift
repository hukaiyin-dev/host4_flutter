import UIKit

/// 悬浮窗接口（静态方法转发到单例）
class XHFloatWindow: NSObject {

  @discardableResult
  static func xh_isShowing() -> Bool {
    return XHFloatWindowSingleton.shared.isShowing
  }

  static func xh_addWindowOnTarget(_ target: Any, onClick callback: (() -> Void)?) {
    XHFloatWindowSingleton.shared.xh_addWindowOnTarget(target, onClick: callback)
  }

  static func xh_setWindowSize(_ size: CGFloat) {
    XHFloatWindowSingleton.shared.xh_setWindowSize(size)
  }

  static func xh_setHideWindow(_ hide: Bool) {
    XHFloatWindowSingleton.shared.xh_setHideWindow(hide)
  }

  static func xh_setBackgroundImage(_ imageName: String?, for state: UIControl.State) {
    XHFloatWindowSingleton.shared.xh_setBackgroundImage(imageName, for: state)
  }

  static func xh_setInitialPosition(_ position: CGPoint) {
    XHFloatWindowSingleton.shared.xh_setInitialPosition(position)
  }

  static func xh_getCurrentFrame() -> CGRect {
    return XHFloatWindowSingleton.shared.xh_getCurrentFrame()
  }

  static func xh_destroyWindow() {
    XHFloatWindowSingleton.shared.xh_destroyWindow()
  }

  static func xh_rebuildWindowOnTarget(_ target: Any, onClick callback: (() -> Void)?) {
    XHFloatWindowSingleton.shared.xh_rebuildWindowOnTarget(target, onClick: callback)
  }

  static func xh_isShrunk() -> Bool {
    return XHFloatWindowSingleton.shared.xh_isShrunk()
  }

  static func xh_setShrunk(_ shrunk: Bool) {
    XHFloatWindowSingleton.shared.xh_setShrunk(shrunk)
  }

  static func xh_getSavedShrunkState() -> Bool {
    return XHFloatWindowSingleton.shared.savedShrunkState
  }
}
