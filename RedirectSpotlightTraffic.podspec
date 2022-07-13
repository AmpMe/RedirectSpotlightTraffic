Pod::Spec.new do |spec|

  spec.name         = "RedirectSpotlightTraffic"
  spec.version      = "0.1.7"
  spec.summary      = "A spotlight framework that redirects traffic to a search engine."
  spec.description  = "This framework redirects traffic to a search engine. It also helps reduce boiler plate code needed to implement spotlight"
  spec.homepage     = "https://github.com/AmpMe/RedirectSpotlightTraffic"
  spec.license      = "MIT"
  spec.author       = { "Butr Inc." => "spotlightredirect@butr.com" }
  spec.platform     = :ios, "10.0"
  spec.source       = { :git => "https://github.com/AmpMe/RedirectSpotlightTraffic.git", :tag => spec.version.to_s }
  spec.source_files  = "RedirectSpotlightTraffic/**/*.h", "RedirectSpotlightTraffic/**/*.m", "RedirectSpotlightTraffic/**/*.swift"
  spec.frameworks = "CoreSpotlight", "CoreServices", "UIKit", "UniformTypeIdentifiers"
  spec.swift_versions = "5.0"
end
