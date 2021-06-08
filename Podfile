# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'



def default_pods
#  pod 'Firebase/Crashlytics'
#  pod 'Firebase/Analytics'
  pod 'Alamofire'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxDataSources'
  pod 'Swinject'
  pod 'SwiftyJSON'
  pod 'IQKeyboardManagerSwift'
  source 'git@gitlab.higgstar.org:mobile/ios_pod_repo.git'
  source 'https://cdn.cocoapods.org/'
  pod 'sharedbu', '1.0.13'
  pod 'SideMenu'
  pod 'Moya/RxSwift'
  pod 'SDWebImage'
  pod "AlignedCollectionViewFlowLayout"
  pod 'TYCyclePagerView'
  use_frameworks!
end

target 'ktobet-asia-ios-qat' do
  default_pods
end

target 'ktobet-asia-ios-qat-v' do
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

