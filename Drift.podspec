Pod::Spec.new do |spec|
  spec.name = "Drift"
  spec.version = "2.4.3"
  spec.summary = "Drift Framework for customer communication"
  spec.homepage = "https://github.com/Driftt/drift-sdk-ios"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Eoin O'Connell" => 'eoin@8bytes.ie' }
  spec.social_media_url = "http://twitter.com/drift"

  spec.platform = :ios, "10.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/Driftt/drift-sdk-ios.git", tag: "#{spec.version}", submodules: false }
  spec.source_files = "Drift/**/*.{h,swift}"
  spec.resource_bundles = {
    'DriftResources' => ['Drift/**/*.xib','Drift/**/*.xcassets']
  }
  spec.swift_version = '5.0'

  spec.dependency 'Starscream', '3.1.1'
  spec.dependency 'AlamofireImage', '~> 4.0'
end
