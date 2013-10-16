Pod::Spec.new do |s|

  s.name         = "MPOAuthConnection"
  s.version      = "0.0.1"
  s.summary      = "An OAuth framework."
  s.description  = "With MPOAuthConnection, all the work of talking to secure web services is taken care of for you so you only have to focus on how you want to use the data the remote web service provides."

  s.homepage     = "http://github.com/meetup/MPOAuthConnection"
  s.license      = { :type => 'BSD' }

  s.author       = "Karl Adam"
  s.platform     = :ios, '5.0'
  s.source       = { :git => "https://github.com/smup/MPOAuthConnection.git", :tag => s.version.to_s }
  s.source_files  = 'Source/Framework/*.{h,m,c}'
  
  s.framework = 'Security'
  s.libraries = 'xml2'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  
end
