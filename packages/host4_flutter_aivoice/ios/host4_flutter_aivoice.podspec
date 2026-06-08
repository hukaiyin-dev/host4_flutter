Pod::Spec.new do |s|
  s.name             = 'host4_flutter_aivoice'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for VolcEngine RTC AI Voice.'
  s.description      = <<-DESC
Flutter plugin for VolcEngine RTC AI Voice.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'BSD' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{swift,m}'
  s.public_header_files = 'Classes/**/*.h'
  s.resources = 'Assets/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.vendored_frameworks = 'Frameworks/VolcEngineRTC.xcframework',
                          'Frameworks/RealXBase.xcframework',
                          'Frameworks/RTCFFmpeg.xcframework',
                          'Frameworks/bytenn.xcframework',
                          'Frameworks/ByteRTCNICOExtension.xcframework',
                          'Frameworks/ByteRTCFFmpegAudioExtension.xcframework',
                          'Frameworks/ByteRTCFDK-AACExtension.xcframework'
end
