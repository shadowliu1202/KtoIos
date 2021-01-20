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
  pod 'sharedbu', :path => '../kto-asia-android/sharedbu/'
  pod 'SideMenu'
  pod 'Moya/RxSwift'
  use_frameworks!
end

target 'ktobet-asia-ios-qat' do
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
    end
  end
end

