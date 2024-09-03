platform :ios, '15.0'

source 'git@gitlab.higgstar.com:mobile/ios_pod_repo.git'
source 'https://github.com/CocoaPods/Specs.git'

def default_pods
  pod 'Firebase/Analytics', '10.27.0'
  pod 'Firebase/Crashlytics', '10.27.0'
  pod 'Firebase/Performance', '10.27.0'
  pod 'Alamofire', '5.4.1'
  pod 'Moya/RxSwift', '15.0.0'
  pod 'RxSwift', '6.5.0'
  pod 'RxCocoa', '6.5.0'
  pod 'RxSwiftExt', '6.2.1'
  pod 'RxDataSources', '5.0.0'
  pod 'RxGesture'
  pod 'Swinject', '2.8.3'
  pod 'SwinjectAutoregistration', '2.8.3'
  pod 'SwiftyJSON', '5.0.0'
  pod 'IQKeyboardManagerSwift', '6.5.6'
  pod 'SideMenu', '6.5.0'
  pod 'SDWebImage', '5.10.4'
  pod "AlignedCollectionViewFlowLayout", '1.1.2'
  pod 'TYCyclePagerView', '1.2.0'
  pod 'lottie-ios', '3.2.3'
  pod 'Connectivity', '5.0.0'
  pod 'NotificationBannerSwift', '3.0.0'
  pod 'RxBlocking', '6.5.0'
  pod 'Puppy', '0.5.0'
  pod 'SnapKit'
  pod 'youtube-ios-player-helper'
  pod 'SwiftKeychainWrapper'
  pod 'SwiftFormat/CLI', '~> 0.49'
  pod 'SwiftSignalRClient'
  pod 'Periphery'
  pod 'NavigationBackport'
  pod 'sharedbu', '2.57.1'
#  pod 'sharedbu', :path => '../kto_shared_bu/sharedbu/build/cocoapods/publish/release'
  use_frameworks!
end

def unitTest_pods
  pod 'MockingbirdFramework', '~> 0.20'
  pod 'ViewInspector'
  pod 'RxTest', '6.5.0'
end


['ktobet-asia-ios','ktobet-asia-ios-vn'].each do |target_name|
  target target_name do
    default_pods
  end
end

target 'KTO-UnitTests' do
  inherit! :search_paths
  default_pods
  unitTest_pods
end

target 'ktobet-asia-iosUITests' do
  inherit! :search_paths
  default_pods
end

target 'AIO-unitTests' do
  inherit! :search_paths
  default_pods
  unitTest_pods
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
    config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
    config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = "YES"
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
        config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end

    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end
