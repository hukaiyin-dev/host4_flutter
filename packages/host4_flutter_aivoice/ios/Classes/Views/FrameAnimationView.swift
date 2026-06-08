import UIKit

/// 帧动画视图
class FrameAnimationView: UIImageView {

  enum AnimationMode {
    case once      // 播放一次
    case loop      // 循环播放
  }

  var frameRate: Int = 30
  var animationMode: AnimationMode = .once

  private var imagePrefix: String
  private var startIndex: Int
  private var count: Int
  private var numberFormat: String
  private var ext: String
  private var images: [UIImage] = []
  private var currentIndex = 0
  private var timer: CADisplayLink?
  private var animateCompletion: (() -> Void)?

  init(imagePrefix: String, startIndex: Int, count: Int,
       numberFormat: String = "%05d", extension ext: String = "png") {
    self.imagePrefix = imagePrefix
    self.startIndex = startIndex
    self.count = count
    self.numberFormat = numberFormat
    self.ext = ext
    super.init(frame: .zero)
    self.contentMode = .scaleAspectFit
    loadImages()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  private func loadImages() {
    for i in 0..<count {
      let idx = startIndex + i
      let name = "\(imagePrefix)\(String(format: numberFormat, idx)).\(ext)"
      if let img = UIImage(named: name) {
        images.append(img)
      }
    }
  }

  func play(completion: (() -> Void)? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.animateCompletion = completion
      self.currentIndex = 0
      self.image = self.images.first

      self.timer = CADisplayLink(target: self, selector: #selector(self.nextFrame))
      self.timer?.preferredFramesPerSecond = self.frameRate
      self.timer?.add(to: .main, forMode: .common)
    }
  }

  @objc private func nextFrame() {
    guard currentIndex < images.count else {
      if animationMode == .loop {
        currentIndex = 0
        self.image = images.first
      } else {
        stop()
        animateCompletion?()
      }
      return
    }
    self.image = images[currentIndex]
    currentIndex += 1
  }

  func stop() {
    timer?.invalidate()
    timer = nil
  }

  deinit {
    stop()
  }

  /// 从中心展开动画（自动在主线程执行）
  func animate(fromCenter center: CGPoint, toSize size: CGSize,
               duration: TimeInterval, damping: CGFloat,
               autoPlay: Bool, completion: @escaping () -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.frame = CGRect(origin: .zero, size: .zero)
      self.center = center
      self.alpha = 0

      UIView.animate(withDuration: duration, delay: 0,
                     usingSpringWithDamping: damping,
                     initialSpringVelocity: 0,
                     options: .curveEaseInOut) {
        self.frame = CGRect(x: center.x - size.width / 2,
                            y: center.y - size.height / 2,
                            width: size.width, height: size.height)
        self.alpha = 1
      } completion: { _ in
        if autoPlay {
          self.play(completion: completion)
        } else {
          completion()
        }
      }
    }
  }
}
