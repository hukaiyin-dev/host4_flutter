import UIKit

/// 全局资源加载工具函数（inline 在所有文件中使用 Bundle.resourceBundle 和 UIImage.resource）
/// 注意：这些是全局函数，同一 module 内所有文件可见

/// 插件资源包
var pluginResourceBundle: Bundle {
  let frameworkBundle = Bundle(for: Host4FlutterAiVoicePlugin.self)

  // CocoaPods 资源 bundle 命名: pod_name.bundle
  let podName = "host4_flutter_aivoice"
  if let url = frameworkBundle.url(forResource: podName, withExtension: "bundle"),
     let bundle = Bundle(url: url) {
    return bundle
  }

  // 备选：直接搜索包含图片的子 bundle
  if let allBundles = frameworkBundle.urls(forResourcesWithExtension: "bundle", subdirectory: nil) {
    for url in allBundles {
      if let bundle = Bundle(url: url) {
        return bundle
      }
    }
  }

  // 最终回退：framework bundle 本身
  return frameworkBundle
}

/// 从插件资源包加载图片
func pluginImage(_ name: String) -> UIImage? {
  let bundle = pluginResourceBundle

  // 优先在资源 bundle 中查找
  if let img = UIImage(named: name, in: bundle, compatibleWith: nil) {
    return img
  }

  // 备选：主 bundle（如果通过 s.resources 全局复制）
  if let img = UIImage(named: name) {
    print("[资源] ✅ 从主 bundle 加载: \(name)")
    return img
  }

  print("[资源] ⚠️ 找不到图片: \(name) in bundle: \(bundle.bundlePath)")
  return nil
}
