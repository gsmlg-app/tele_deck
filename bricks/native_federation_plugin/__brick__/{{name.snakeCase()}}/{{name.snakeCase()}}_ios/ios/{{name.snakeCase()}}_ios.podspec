Pod::Spec.new do |s|
  s.name             = '{{name.snakeCase()}}_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of {{package_prefix.snakeCase()}}_{{name.snakeCase()}}'
  s.description      = <<-DESC
iOS implementation of {{package_prefix.snakeCase()}}_{{name.snakeCase()}} plugin.
                       DESC
  s.homepage         = 'https://github.com/{{package_prefix.snakeCase()}}'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { '{{author}}' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
