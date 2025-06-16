install! 'cocoapods'
workspace 'CastBrowser-iOS.xcworkspace'

platform :ios, '13.0'
use_frameworks! :linkage => :static

target 'CastBrowser-iOS' do
  # Pods for CastBrowser-iOS
  pod 'google-cast-sdk', '~> 4.8'
  pod 'Protobuf', '~> 3.24'

  target 'CastBrowser-iOSTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'CastBrowser-iOSUITests' do
    # Pods for testing
  end
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # ensure all pods use iOS 13.0
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      # if you’re on M1/M2 and still get arch errors, exclude arm64 for simulator
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
