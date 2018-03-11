# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'carpoolingudec' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!

  # Pods for UdeC Carpooling
  pod 'AFNetworking', '~> 3.0'
  pod 'Firebase/Core'
#  pod 'Firebase/Messaging'
  pod 'GoogleMaps'
  pod 'GooglePlaces'
  pod 'MFSideMenu', :git => 'git@github.com:alejandroivan/MFSideMenu.git'
  pod 'NSUserDefaults-Convenience', :git => 'https://github.com/alejandroivan/NSUserDefaults-Convenience.git'

end


## Post install hook
post_install do |pi|
    pi.pods_project.targets.each do |t|
        t.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
        end
    end
end
