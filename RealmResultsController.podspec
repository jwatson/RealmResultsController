Pod::Spec.new do |s|
  s.name                = "RealmResultsController"
  s.version             = "0.2.1"
  s.summary             = "A NSFetchedResultsController implementation for Realm written in Swift"
  s.homepage            = "https://github.com/teambox/RealmResultsController"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = "Redbooth"
  s.source              = { :git => "https://github.com/teambox/RealmResultsController.git", :tag => s.version.to_s }
  s.platform            = :ios, '8.0'
  s.source_files        = 'Source'
  s.frameworks          = 'UIKit'
  s.requires_arc        = true
  s.social_media_url    = 'https://twitter.com/redboothhq'
  s.dependency          'Realm'
  s.dependency          'RealmSwift'
end
