import UIKit

/// 全局资源加载工具函数（inline 在所有文件中使用 Bundle.resourceBundle 和 UIImage.resource）
/// 注意：这些是全局函数，同一 module 内所有文件可见

/// 插件资源包
var pluginResourceBundle: Bundle {
  let frameworkBundle = Bundle(for: Host4FlutterAiVoicePlugin.self)
  if let url = frameworkBundle.url(forResource: "host4_flutter_aivoice", withExtension: "bundle"),
     let bundle = Bundle(url: url) {
    return bundle
  }
  return frameworkBundle
}

/// 从插件资源包加载图片
func pluginImage(_ name: String) -> UIImage? {
  let bundle = pluginResourceBundle
  let image = UIImage(named: name, in: bundle, compatibleWith: nil)
  if image == nil {
    print("[资源] ⚠️ 找不到图片: \(name)")
  } else {
    print("[资源] ✅ 加载图片: \(name)")
  }
  return image
}
