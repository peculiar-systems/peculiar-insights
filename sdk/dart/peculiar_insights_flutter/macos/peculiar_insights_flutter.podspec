Pod::Spec.new do |s|
  s.name             = 'peculiar_insights_flutter'
  s.version          = '0.1.0'
  s.summary          = 'Flutter bindings for the Peculiar Insights client.'
  s.description      = 'Carries the privacy manifest for the data the client collects.'
  s.homepage         = 'https://github.com/peculiar-systems/peculiar-insights'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Peculiar Systems' => 'contact@peculiar.systems' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resource_bundles = { 'peculiar_insights_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '11.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
