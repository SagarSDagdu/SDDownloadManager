Pod::Spec.new do |s|
s.name             = 'SDDownloadManager'
s.version          = '2.0.0'
s.summary          = 'A simple, robust and elegant download manager written in Swift'

s.description      = <<-DESC
SDDownloadManager is based on URLSession APIs and provides closure syntax APIs for keeping track of progress and completion of downloads.
DESC

s.homepage         = 'https://github.com/SagarSDagdu/SDDownloadManager'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Sagar Dagdu' => 'shags032@gmail.com' }
s.source           = { :git => 'https://github.com/SagarSDagdu/SDDownloadManager.git', :tag => s.version.to_s }

s.swift_version = '5.0'
s.ios.deployment_target = '12.0'
s.framework    = 'UserNotifications'
s.source_files = 'SDDownloadManager/Classes/*.swift'

end
