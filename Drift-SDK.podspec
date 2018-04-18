Pod::Spec.new do |spec|
  spec.name = "Drift-SDK"
  spec.version = "2.1"
  spec.summary = "Drift Framework for customer communication"
  spec.homepage = "https://github.com/Driftt/drift-sdk-ios"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Eoin O'Connell" => 'eoin@8bytes.ie' }
  spec.social_media_url = "http://twitter.com/drift"

  spec.platform = :ios, "9.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/Driftt/drift-sdk-ios.git", tag: "#{spec.version}", submodules: false }
  spec.source_files = "Drift/**/*.{h,swift}"
  spec.resources = ['Drift/**/*.xib','Drift/**/*.xcassets']
  spec.swift_version = '4.1'

  spec.dependency 'Starscream'
  spec.dependency 'ObjectMapper', '~> 3.0'
  spec.dependency 'AlamofireImage', '~> 3.0'
  spec.dependency 'SVProgressHUD', '~> 2.0'
end
