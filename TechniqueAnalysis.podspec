
Pod::Spec.new do |s|
  s.name             = 'TechniqueAnalysis'
  s.version          = '0.1.0'
  s.summary          = 'A CocoaPod to track body motion and analyze exercise technique.'
  s.description      = <<-DESC
This is a CocoaPod which processes video footage of a user doing an exercise and provides feedback on the user's form. The general idea is to capture a timeseries, where each data point contains an array of body point locations in 2D space, along with a confidence level on the accuracy of each body point. Timeseries are compared using k-Nearest Neighbor and Dynamic Time Warping to find the nearest neighbor.
                       DESC
  s.homepage         = 'https://github.com/trevphil/TechniqueAnalysis'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'trevphil' => 'trevor.j.phillips@uconn.edu' }
  s.source           = { :git => 'https://github.com/trevphil/TechniqueAnalysis.git', :tag => s.version.to_s }
  s.swift_version 	 = '4.2'
  s.platform = :ios, '11.0'
  s.source_files = 'Models/**/*', 'Utils/**/*', 'Views/**/*'
  s.frameworks = 'UIKit', 'AVKit', 'CoreML', 'AVFoundation', 'Vision', 'CoreMedia'
end
