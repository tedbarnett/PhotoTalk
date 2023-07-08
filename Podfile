source 'https://cdn.cocoapods.org/'
platform :ios, '14'
use_frameworks!

# Shared pods b/w targets
def my_photo_reviewer_pods
#  pod 'Firebase'
#  pod 'Firebase/Auth'
#  pod 'Firebase/Storage'
#  pod 'Firebase/Database'
  pod 'GooglePlaces'
end

target 'MyPhotoReviewer-Development' do
  my_photo_reviewer_pods
end

target 'MyPhotoReviewer-Distribution' do
  my_photo_reviewer_pods
end

# Commong settings for pods
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
    end
  end
end
