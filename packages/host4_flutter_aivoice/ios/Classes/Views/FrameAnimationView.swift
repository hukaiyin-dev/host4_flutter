import UIKit

private var frameImageCache = NSCache<NSString, NSArray>()

class FrameAnimationView: UIImageView {

  enum AnimationMode { case once, loop }

  var frameRate: Int = 40
  var animationMode: AnimationMode = .once

  private var images: [UIImage] = []
  private var currentIndex = 0
  private var timer: CADisplayLink?
  private var animateCompletion: (() -> Void)?

  init(imagePrefix: String, startIndex: Int, count: Int,
       numberFormat: String = "%05d", extension ext: String = "png") {
    super.init(frame: .zero)
    contentMode = .scaleAspectFit
    isHidden = true
    images = Self.loadCached(prefix: imagePrefix, start: startIndex, count: count,
                             format: numberFormat, ext: ext)
  }

  required init?(coder: NSCoder) { fatalError() }

  static func loadCached(prefix: String, start: Int, count: Int, format: String, ext: String) -> [UIImage] {
    let key = "\(prefix)_\(start)_\(count)" as NSString
    if let cached = frameImageCache.object(forKey: key) as? [UIImage], !cached.isEmpty { return cached }
    var r: [UIImage] = []
    r.reserveCapacity(count)
    for i in 0..<count {
      let name = "\(prefix)\(String(format: format, start + i)).\(ext)"
      if let img = pluginImage(name) { r.append(img) }
    }
    print("[Anim] loadCached \(r.count)/\(count)")
    frameImageCache.setObject(r as NSArray, forKey: key)
    return r
  }

  func play(completion: (() -> Void)? = nil) {
    guard !images.isEmpty else { completion?(); return }
    backgroundColor = .clear  // 移除调试底色
    layer.cornerRadius = 0
    animateCompletion = completion
    currentIndex = 0
    image = images.first
    timer = CADisplayLink(target: self, selector: #selector(nextFrame))
    timer?.preferredFramesPerSecond = frameRate
    timer?.add(to: .main, forMode: .common)
  }

  @objc private func nextFrame() {
    guard currentIndex < images.count else {
      stop()
      if animationMode == .loop { currentIndex = 0; image = images.first }
      else { animateCompletion?() }
      return
    }
    image = images[currentIndex]
    currentIndex += 1
  }

  func stop() { timer?.invalidate(); timer = nil }
  deinit { stop() }

  // MARK: - Animation (transform scale 0.01→1.0, alpha 0→1)

  func animate(fromCenter center: CGPoint, toSize size: CGSize,
               duration: TimeInterval, damping: CGFloat,
               autoPlay: Bool, completion: @escaping () -> Void) {
    let t0 = CACurrentMediaTime()
    frame = CGRect(x: center.x - size.width / 2,
                   y: center.y - size.height / 2,
                   width: size.width, height: size.height)
    alpha = 0
    transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    isHidden = false
    clipsToBounds = true
    layer.cornerRadius = size.width / 2  // 圆形
    backgroundColor = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.4) // 淡蓝色调试底
    print("[Anim] start fullSize=\(size), alpha=0, scale=0.01, debug=on")

    UIView.animate(withDuration: duration, delay: 0,
                   options: .curveEaseOut) {
      self.alpha = 1
      self.transform = .identity
    } completion: { [weak self] _ in
      let t = String(format: "%.1f", CACurrentMediaTime() - t0)
      print("[Anim] expand done \(t)s images=\(self?.images.count ?? 0)")
      guard let self = self else { return }
      if autoPlay { self.play(completion: completion) } else { completion() }
    }
  }
}
