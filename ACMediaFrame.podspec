
Pod::Spec.new do |s|

  s.name         = "ACMediaFrame"
  s.version      = "2.0.6"
  s.summary      = "An easy way to display image or video form album or camera, and get more info of image or video to upload and so on."
  s.homepage     = "https://github.com/honeycao/ACMediaFrame"
  s.license      = "MIT"
  s.author             = { "ArthurCao" => "honeycao9268@163.com" }
  s.platform     = :ios, "8.0"

  s.source       = { 
    :git => "https://github.com/honeycao/ACMediaFrame.git", 
    :tag => "#{s.version}" 
  }
  s.source_files  =  "ACMediaFrame/*.{h,m}", "ACMediaFrame/Libraries/*.{h,m}"
  s.resources = "ACMediaFrame/ACMediaFrame.bundle"
  
  s.requires_arc = true

  s.dependency 'TZImagePickerController'
  s.dependency 'SDWebImage'

end
