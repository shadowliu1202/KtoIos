# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'



def default_pods
#  pod 'Firebase/Crashlytics'
#  pod 'Firebase/Analytics'
  pod 'Alamofire', '5.4.1'
  pod 'RxSwift', '5.1.1'
  pod 'RxCocoa', '5.1.1'
  pod 'RxSwiftExt', '~> 5'
  pod 'RxDataSources', '4.0.1'
  pod 'Swinject', '2.7.1'
  pod 'SwiftyJSON', '5.0.0'
  pod 'IQKeyboardManagerSwift', '6.5.6'
  source 'git@gitlab.higgstar.org:mobile/ios_pod_repo.git'
  source 'https://cdn.cocoapods.org/'
  pod 'sharedbu', '1.9.3'
  pod 'SideMenu', '6.5.0'
  pod 'Moya/RxSwift', '14.0.0'
  pod 'SDWebImage', '5.10.4'
  pod "AlignedCollectionViewFlowLayout", '1.1.2'
  pod 'TYCyclePagerView', '1.2.0'
  pod 'lottie-ios', '3.2.3'
  use_frameworks!
end

target 'ktobet-asia-ios-qat' do
  default_pods
end

target 'ktobet-asia-ios-staging' do
  default_pods
end

target 'ktobet-asia-ios' do
  default_pods
end

target 'ktobet-asia-iosTests' do
  inherit! :search_paths
  # Pods for testing
end

target 'ktobet-asia-iosUITests' do
  # Pods for testing
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = "YES"
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
    end
  end
end

