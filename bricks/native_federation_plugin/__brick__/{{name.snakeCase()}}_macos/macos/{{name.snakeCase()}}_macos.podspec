Pod::Spec.new do |s|
  s.name             = '{{name.snakeCase()}}_macos'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation of {{package_prefix.snakeCase()}}_{{name.snakeCase()}}'
  s.description      = <<-DESC
macOS implementation of {{package_prefix.snakeCase()}}_{{name.snakeCase()}} plugin.
                       DESC
  s.homepage         = 'https://github.com/{{package_prefix.snakeCase()}}'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { '{{author}}' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
