import UIKit

/// 可拖拽悬浮按钮
class XHDraggableButton: UIButton {

  var dragEnable = true
  private var isDragged = false

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    isDragged = false
    super.touchesBegan(touches, with: event)
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard dragEnable, let touch = touches.first else {
      super.touchesMoved(touches, with: event)
      return
    }

    let current = touch.location(in: self.superview)
    let previous = touch.previousLocation(in: self.superview)
    let offsetX = current.x - previous.x
    let offsetY = current.y - previous.y

    // 判断是否有明显位移
    if abs(offsetX) > 2 || abs(offsetY) > 2 {
      isDragged = true
    }

    center = CGPoint(x: center.x + offsetX, y: center.y + offsetY)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard dragEnable else {
      super.touchesEnded(touches, with: event)
      return
    }

    if isDragged {
      // 拖拽结束，吸附到边缘
      let margin: CGFloat = 10
      var newCenter = center
      let halfW = bounds.width / 2
      let halfH = bounds.height / 2
      let screenW = UIScreen.main.bounds.width
      let screenH = UIScreen.main.bounds.height
      let maxX = screenW - halfW - margin
      let minX = halfW + margin
      let maxY = screenH - halfH - margin
      let minY = halfH + safeAreaTop + margin

      if newCenter.x > maxX { newCenter.x = maxX }
      if newCenter.x < minX { newCenter.x = minX }
      if newCenter.y > maxY { newCenter.y = maxY }
      if newCenter.y < minY { newCenter.y = minY }

      UIView.animate(withDuration: 0.25) {
        self.center = newCenter
      }
    } else {
      // 没有拖动，触发点击事件（让 super 处理 UIControl 的 target-action）
      super.touchesEnded(touches, with: event)
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
  }

  private var safeAreaTop: CGFloat {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.keyWindow?.safeAreaInsets.top ?? 44
    }
    return 20
  }
}
