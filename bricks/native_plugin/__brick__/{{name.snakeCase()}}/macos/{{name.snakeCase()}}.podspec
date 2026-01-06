Pod::Spec.new do |s|
  s.name             = '{{name.snakeCase()}}'
  s.version          = '0.0.1'
  s.summary          = '{{description}}'
  s.description      = <<-DESC
{{description}}
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { '{{author}}' => 'author@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform         = :osx, '10.14'
  s.swift_version    = '5.0'
end
