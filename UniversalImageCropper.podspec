Pod::Spec.new do |s|
  s.name             = 'UniversalImageCropper'
  s.version          = '0.1.0' # Set your library version here
  s.summary          = 'A brief description of UniversalImageCropper.'
  s.description      = 'Some Description'
  s.homepage         = 'https://example.com/UniversalImageCropper' # Your project's homepage
  s.license          = { :type => 'MIT', :file => 'LICENSE' } # Your license type and file
  s.author           = { 'Your Name' => 'your@email.com' }
  s.source           = { :git => 'https://github.com/username/UniversalImageCropper.git', :tag => s.version.to_s }
  s.platforms        = { :ios => '14.0' }
  s.swift_version    = '5.9'
  s.source_files     = 'Sources/**/*.{swift}' # Adjust this to the paths of your source files
end