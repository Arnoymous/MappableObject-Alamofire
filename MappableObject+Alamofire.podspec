#
# Be sure to run `pod lib lint MappableObjectAlamofire.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MappableObject+Alamofire'
  s.version          = '0.3.0'
  s.summary          = 'Alamofire extension for MappableObject'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Arnoymous/MappableObject-Alamofire'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Arnoymous' => 'arnaud.dorgans@gmail.com' }
  s.source           = { :git => 'https://github.com/Arnoymous/MappableObject-Alamofire.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/arnauddorgans'

  s.watchos.deployment_target = '2.0'
  s.ios.deployment_target = '8.0'
  #s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'MappableObjectAlamofire/Classes/**/*'
  
  # s.resource_bundles = {
  #   'MappableObjectAlamofire' => ['MappableObjectAlamofire/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'MappableObject', '~> 0.3.2'
  s.dependency 'Alamofire', '~> 4.5.0'
end
