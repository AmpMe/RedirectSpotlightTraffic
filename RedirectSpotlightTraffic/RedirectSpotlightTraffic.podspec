Pod::Spec.new do |spec|
  spec.name         = "RedirectSpotlightTraffic"
  spec.version      = "0.0.1"
  spec.summary      = "Redirects spotlight traffic to a search engine."
  spec.description  = "Implements Spotlight for you and redirects the traffic to a search engine."
  spec.homepage     = "https://github.com/AmpMe/RedirectSpotlightTraffic.git"
  spec.license      = "MIT"
  spec.author       = { "RedirectSpotlightTraffic" => "redirectspotlighttraffic@butr.com" }
  spec.platform     = :ios, "15.2"
  spec.source       = { :git => "https://github.com/AmpMe/RedirectSpotlightTraffic.git", :tag => spec.version.to_s }
  spec.source_files  = "RedirectSpotlightTraffic/**/*"
  spec.frameworks = "CoreSpotlight", "CoreServices", "UIKit", "UniformTypeIdentifiers"
  spec.swift_versions = "5.0"
end
