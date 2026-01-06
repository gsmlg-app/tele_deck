# {{name.titleCase()}}

{{description}}

## Features

- Cross-platform support (Android, iOS, Linux, macOS, Windows)
- Native platform integration
- Method channel communication
- Built-in caching
- Type-safe API

## Supported Platforms

{{#support_android}}
- Android
{{/support_android}}
{{#support_ios}}
- iOS
{{/support_ios}}
{{#support_linux}}
- Linux
{{/support_linux}}
{{#support_macos}}
- macOS
{{/support_macos}}
{{#support_windows}}
- Windows
{{/support_windows}}
{{#support_web}}
- Web
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

// Get plugin instance
final plugin = {{name.pascalCase()}}.instance;

// Get data
final data = await plugin.getData();
print('Platform: ${data.platform}');
print('Timestamp: ${data.timestamp}');
print('Additional Data: ${data.additionalData}');

// Refresh cached data
await plugin.refresh();
```

## Development

### Running Tests

```bash
# Test all packages
melos run test

# Test this package
cd {{name.snakeCase()}} && flutter test
```

### Adding New Features

1. Update the Dart API in `lib/src/{{name.snakeCase()}}.dart`
2. Implement the feature in each platform's native code
3. Add tests

## License

MIT License - see LICENSE file for details.

## Author

{{author}}
