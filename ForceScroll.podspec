Pod::Spec.new do |s|
  s.name         = "ForceScroll"
  s.version      = "0.1001"
  s.summary      = "Force Scroll Navigation"
  s.homepage     = "https://github.com/nsrgh/ios-ForceScroll"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Andrey Rylov" => "angst.ru@gmail.com" }
  s.social_media_url   = ""
  s.ios.deployment_target = "8.3"
  s.source       = { :git => "https://github.com/nsrgh/ios-ForceScroll.git", :tag => "0.1001" }
  s.source_files  = "Sources/**/*"
  s.frameworks  = "UIKit"
end
