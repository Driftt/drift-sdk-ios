platform :ios, '9.0'
use_frameworks!

target 'Drift-SDK' do
    pod 'ObjectMapper', '~> 2.0'
    pod 'LayerKit', '~> 0.17'
    pod 'SlackTextViewController', '~> 1.9.3'
    pod 'AlamofireImage', '~> 3.0'
    pod 'SVProgressHUD', '~> 1.1'
end

target 'DriftTests' do
    pod 'ObjectMapper', '~> 2.0'
    pod 'LayerKit', '~> 0.17'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
