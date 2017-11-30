Pod::Spec.new do |spec|
  spec.name = "Drift"
  spec.version = "1.2.5"
  spec.summary = "Drift Framework for customer communication"
  spec.homepage = "https://github.com/Driftt/drift-sdk-ios"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Eoin O'Connell" => 'eoin@8bytes.ie' }
  spec.social_media_url = "http://twitter.com/drift"

  spec.platform = :ios, "8.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/Driftt/drift-sdk-ios.git", tag: "#{spec.version}", submodules: false }
  spec.source_files = "Drift/**/*.{h,swift}"
  spec.resources = ['Drift/**/*.xib','Drift/**/*.xcassets']


  spec.dependency 'Starscream'
  spec.dependency 'ObjectMapper', '~> 3.0'
  spec.dependency 'SlackTextViewController', '~> 1.9.3'
  spec.dependency 'AlamofireImage', '~> 3.0'
  spec.dependency 'SVProgressHUD', '~> 2.0'

  spec.pod_target_xcconfig = {
    'SWIFT_VERSION' => '4.0',
  }

end
