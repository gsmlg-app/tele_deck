Pod::Spec.new do |s|
  s.name             = 'tele_crash_logger'
  s.version          = '0.0.1'
  s.summary          = 'Native crash logging and reporting'
  s.description      = <<-DESC
Native crash logging and reporting
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'GSMLG Team' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'
end
