---
name: flutter-plugin
description: Guide for creating federated native plugins in app_plugin with platform-specific implementations
---

# Flutter Plugin Development Skill

This skill guides the creation of federated native plugins following this project's architecture.

## When to Use

Trigger this skill when:
- Creating a native plugin with platform-specific code
- Adding new platform support to an existing plugin
- User asks to "create a plugin", "add native functionality", or "implement platform-specific feature"

## Mason Template

**Always use Mason template first:**

```bash
mason make native_federation_plugin \
  --name plugin_name \
  --description "Plugin description" \
  --package_prefix app \
  -o app_plugin

# Platform support options (all default to true):
# --support_android
# --support_ios
# --support_linux
# --support_macos
# --support_windows
# --support_web (default: false)
```

## Federated Plugin Architecture

This project uses Flutter's federated plugin pattern:

```
app_plugin/
├── plugin_name/                        # Main package (app-facing API)
├── plugin_name_platform_interface/     # Platform interface (abstract)
├── plugin_name_android/                # Android implementation (Kotlin)
├── plugin_name_ios/                    # iOS implementation (Swift)
├── plugin_name_linux/                  # Linux implementation (C++)
├── plugin_name_macos/                  # macOS implementation (Swift)
└── plugin_name_windows/                # Windows implementation (C++)
```

## Package Responsibilities

### Main Package (`plugin_name/`)
- App-facing API
- Re-exports platform interface types
- Delegates to platform implementations

```dart
// lib/src/plugin_name.dart
class PluginName {
  static PluginNamePlatform get _platform => PluginNamePlatform.instance;

  static Future<String> getData() => _platform.getData();
}
```

### Platform Interface (`plugin_name_platform_interface/`)
- Defines abstract interface
- Shared data classes
- Method channel constants

```dart
// lib/plugin_name_platform_interface.dart
abstract class PluginNamePlatform extends PlatformInterface {
  static PluginNamePlatform _instance = MethodChannelPluginName();

  static PluginNamePlatform get instance => _instance;

  Future<String> getData();
}
```

### Platform Implementations
Each platform package implements the interface using native code:

- **Android**: Kotlin + Method Channel
- **iOS/macOS**: Swift + Method Channel
- **Linux/Windows**: C++ + Method Channel

## Workspace Registration

Add ALL plugin packages to root `pubspec.yaml`:

```yaml
workspace:
  # existing packages...
  - app_plugin/plugin_name
  - app_plugin/plugin_name_platform_interface
  - app_plugin/plugin_name_android
  - app_plugin/plugin_name_ios
  - app_plugin/plugin_name_linux
  - app_plugin/plugin_name_macos
  - app_plugin/plugin_name_windows
```

## Method Channel Pattern

### Dart Side (Platform Interface)
```dart
class MethodChannelPluginName extends PluginNamePlatform {
  final methodChannel = const MethodChannel('app_plugin_name');

  @override
  Future<String> getData() async {
    final result = await methodChannel.invokeMethod<String>('getData');
    return result ?? '';
  }
}
```

### Native Side (Example: Swift/iOS)
```swift
public class PluginNamePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "app_plugin_name",
      binaryMessenger: registrar.messenger()
    )
    let instance = PluginNamePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getData":
      result("Data from iOS")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

## Dependencies

Main package `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  app_plugin_name_platform_interface: any
  app_plugin_name_android: any
  app_plugin_name_ios: any
  app_plugin_name_linux: any
  app_plugin_name_macos: any
  app_plugin_name_windows: any
```

Platform implementation packages:
```yaml
dependencies:
  flutter:
    sdk: flutter
  app_plugin_name_platform_interface: any
```

## Adding New Features

1. **Update Platform Interface**
   - Add method to abstract class
   - Add to method channel implementation

2. **Implement on Each Platform**
   - Add native code in each platform package
   - Handle the new method channel call

3. **Update Main API**
   - Expose new functionality in main package

4. **Add Tests**
   - Unit tests for Dart code
   - Integration tests for native code

## Testing

```bash
# Test all plugin packages
melos run test

# Test specific platform
cd app_plugin/plugin_name && flutter test
cd app_plugin/plugin_name_android && flutter test
```

## Reference Implementation

`app_client_info` serves as the reference federated plugin:

- Main API: `app_plugin/client_info/`
- Interface: `app_plugin/client_info_platform_interface/`
- Platforms: `client_info_android`, `client_info_ios`, etc.

## Usage in App

```dart
import 'package:app_plugin_name/app_plugin_name.dart';

// Get instance
final plugin = PluginName.instance;

// Call methods
final data = await plugin.getData();
```
