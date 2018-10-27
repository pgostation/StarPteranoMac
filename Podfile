source 'https://github.com/CocoaPods/Specs.git'
platform :osx, '10.10'
use_frameworks!

target 'StarPteranoMac' do
pod 'Starscream'
pod 'APNGKit'
pod 'FirebaseCore', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :branch => 'master'
pod 'FirebaseAuth', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :branch => 'master'
pod 'FirebaseDatabase', :git => 'https://github.com/firebase/firebase-ios-sdk.git', :branch => 'master'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
        end
        
    end
end

# EXPANDED_CODE_SIGN_IDENTITY: unbound variableでビルドエラーになったら
# Pods-<App>-frameworks.shで
# if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}"を
# if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}"にする
# https://github.com/CocoaPods/CocoaPods/issues/8000
#
