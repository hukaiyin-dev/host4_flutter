// MARK: - 仅让悬浮按钮接收触摸、其余透传的容器
class XHFloatContainer: UIView {
  var passThroughDelegate: ((CGPoint) -> Bool)?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard passThroughDelegate?(point) == true else {
      // 不在按钮区域，透传到下层
      return nil
    }
    return super.hitTest(point, with: event)
  }
}
