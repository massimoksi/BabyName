source 'https://github.com/CocoaPods/Specs.git'

platform :ios, "8.0"

target "BabyName" do
    pod 'MSDynamicsDrawerViewController', '~> 1.5'
    pod 'MGSwipeTableCell'
    pod 'StaticDataTableViewController', '~> 2.0'
end

target "BabyNameTests" do

end

post_install do |installer|
    require 'fileutils'
    FileUtils.copy('Pods/Target Support Files/Pods-BabyName/Pods-BabyName-acknowledgements.plist', 'BabyName/Acknowledgements.plist')
end


