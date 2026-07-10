Pod::Spec.new do |s|
  s.name             = 'host4_flutter_simulator_storage'
  s.version          = '0.0.1'
  s.summary          = 'Simulator ROM storage scanning helpers for Host4 apps.'
  s.description      = <<-DESC
Reusable iOS TF card ROM folder picker and scanner for Host4 Flutter apps.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Host4' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
