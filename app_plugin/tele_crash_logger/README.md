# Tele Crash Logger

Native crash logging and reporting

## Features

- Cross-platform support (Android, iOS, Linux, macOS, Windows)
- Native platform integration
- Method channel communication
- Built-in caching
- Type-safe API

## Supported Platforms


- Android


- iOS






## Installation

Add this plugin to your project's `pubspec.yaml`:

```yaml
dependencies:
  tele_tele_crash_logger: any
```

Then run:

```bash
melos bootstrap
```

## Usage

```dart
import 'package:tele_tele_crash_logger/tele_tele_crash_logger.dart';

// Get plugin instance
final plugin = TeleCrashLogger.instance;

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
cd tele_crash_logger && flutter test
```

### Adding New Features

1. Update the Dart API in `lib/src/tele_crash_logger.dart`
2. Implement the feature in each platform's native code
3. Add tests

## License

MIT License - see LICENSE file for details.

## Author

GSMLG Team
