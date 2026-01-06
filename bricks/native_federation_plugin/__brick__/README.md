# {{name.titleCase()}}

{{description}}

## Features

- ✅ Cross-platform support (Android, iOS, Linux, macOS, Windows)
- ✅ Native platform integration
- ✅ Method channel communication
- ✅ Built-in caching
- ✅ Type-safe API

## Supported Platforms

{{#support_android}}- ✅ Android
{{/support_android}}{{#support_ios}}- ✅ iOS
{{/support_ios}}{{#support_linux}}- ✅ Linux
{{/support_linux}}{{#support_macos}}- ✅ macOS
{{/support_macos}}{{#support_windows}}- ✅ Windows
{{/support_windows}}{{#support_web}}- ✅ Web
{{/support_web}}

## Installation

Add this plugin to your project's `pubspec.yaml`:

```yaml
dependencies:
  {{package_prefix.snakeCase()}}_{{name.snakeCase()}}: any
```

Then run:

```bash
melos bootstrap
```

## Usage

```dart
import 'package:{{package_prefix.snakeCase()}}_{{name.snakeCase()}}/{{package_prefix.snakeCase()}}_{{name.snakeCase()}}.dart';

// Get {{name.lowerCase()}} instance
final {{name.camelCase()}} = {{name.pascalCase()}}.instance;

// Get data
final data = await {{name.camelCase()}}. getData();
print('Platform: ${data.platform}');
print('Timestamp: ${data.timestamp}');
print('Additional Data: ${data.additionalData}');

// Refresh cached data
await {{name.camelCase()}}.refresh();
```

## Architecture

This plugin uses a federated plugin architecture:

- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}**: Main package (app-facing API)
- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_platform_interface**: Platform interface definition
{{#support_android}}- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_android**: Android implementation
{{/support_android}}{{#support_ios}}- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_ios**: iOS implementation
{{/support_ios}}{{#support_linux}}- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_linux**: Linux implementation
{{/support_linux}}{{#support_macos}}- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_macos**: macOS implementation
{{/support_macos}}{{#support_windows}}- **{{package_prefix.snakeCase()}}_{{name.snakeCase()}}_windows**: Windows implementation
{{/support_windows}}

## Development

### Running Tests

```bash
# Test all packages
melos run test

# Test specific package
cd {{name.snakeCase()}} && flutter test
```

### Adding New Features

1. Update the platform interface in `{{name.snakeCase()}}_platform_interface`
2. Implement the feature in each platform-specific package
3. Update the main API in `{{name.snakeCase()}}`
4. Add tests

## License

MIT License - see LICENSE file for details.

## Author

{{author}}
