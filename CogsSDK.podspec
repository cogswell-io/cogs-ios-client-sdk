#
# Be sure to run `pod lib lint CogsSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CogsSDK'
  s.version          = '1.0.12'
  s.summary          = 'CogsSDK is the Swift client SDK of Cogswell publish/subscribe platform.'

# This description is used to generate tags and improve search results.

  s.description      = <<-DESC
    CogsSDK is the Swift client SDK of Cogswell publish/subscribe platform.
    Cogswell is a pub/sub and complex event processing platform designed to process data using a sophisticated rules engine. Get the information you need to make decisions in real time. Define rules in our web console, and use REST API or SDKs to send event data and subscribe client applications. Cogswell.io gives you the power to process critical information and take immediate action.
        https://cogswell.io
                       DESC

  s.homepage         = 'https://inceptdev.com/divanov/aviata-cogs-ios-client-sdk'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'Aviata Inc.' => 'https://cogswell.io' }
  s.source           = { :git => 'https://inceptdev.com/divanov/aviata-cogs-ios-client-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'CogsSDK/Classes/**/*'
  s.dependency 'CryptoSwift'
  s.dependency 'Starscream', '~> 2.0.3'
end
