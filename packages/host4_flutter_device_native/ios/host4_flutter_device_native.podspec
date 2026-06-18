#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint host4_flutter_device_native.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  disable_native_sdks = ENV.fetch('HOST4_DISABLE_DEVICE_NATIVE_SDKS', '1') == '1'

  s.name             = 'host4_flutter_device_native'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin shell for host4 native device communication.'
  s.description      = <<-DESC
Flutter plugin shell for host4 native device communication.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = disable_native_sdks ? 'Classes/Host4FlutterDeviceNativePlugin.swift' : 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  unless disable_native_sdks
    s.vendored_frameworks = [
      'Frameworks/BluetoothKit.xcframework',
      'Frameworks/MFiKit.xcframework',
      'Frameworks/GMacroProtocolSDK.xcframework',
    ]
  end
  s.frameworks = disable_native_sdks ? ['UIKit'] : ['CoreBluetooth', 'ExternalAccessory', 'GameController', 'UIKit']

  # Flutter.framework does not contain a i386 slice.
  pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  if disable_native_sdks
    pod_target_xcconfig['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) HOST4_DISABLE_GMACRO_SDK'
  end
  s.pod_target_xcconfig = pod_target_xcconfig
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'host4_flutter_device_native_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
