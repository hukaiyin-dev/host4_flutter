import UIKit

/// UIApplication 扩展 - 获取顶层视图控制器和导航控制器
extension UIApplication {

  /// 获取当前显示的 ViewController
  func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let base = base ?? connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController

    if let nav = base as? UINavigationController {
      return topViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      return topViewController(base: tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
      return topViewController(base: presented)
    }
    return base
  }

  /// 获取当前导航控制器
  func topNavigationController() -> UINavigationController? {
    guard let top = topViewController() else { return nil }

    if let nav = top as? UINavigationController { return nav }
    if let nav = top.navigationController { return nav }

    // 尝试从 window 的 rootViewController 获取
    return connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController as? UINavigationController
  }
}
