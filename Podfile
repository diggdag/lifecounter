# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '17.6'

target 'lifeCounter' do
  use_modular_headers!
  use_frameworks!
  pod 'Toast-Swift', '~> 5.0.0'
#  pod 'FirebaseAnalytics'
  pod 'Google-Mobile-Ads-SDK', '< 11.0'
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
