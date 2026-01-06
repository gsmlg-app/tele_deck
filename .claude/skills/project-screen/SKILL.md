---
name: project-screen
description: Guide for creating screens with routing conventions (name/path constants) and adaptive scaffold (project)
---

# Flutter Screen Development Skill

This skill guides the creation of screens following this project's routing and layout conventions.

## When to Use

Trigger this skill when:
- Creating a new screen or page
- Adding a route to the application
- User asks to "create a screen", "add a page", or "implement a new view"

## Mason Template

**Always use Mason template first:**

```bash
# Basic screen with optional subfolder
mason make screen --name ScreenName --folder subfolder

# Options available:
# --has_adaptive_scaffold: Use AppAdaptiveScaffold (default: true)
# --has_app_bar: Include SliverAppBar (default: true)
```

## Project Structure

Screens are organized in `lib/screens/` by domain:

```
lib/screens/
├── app/                    # App-level screens (splash, error)
│   ├── splash_screen.dart
│   └── error_screen.dart
├── home/                   # Home feature
│   └── home_screen.dart
├── settings/               # Settings feature
│   ├── settings_screen.dart
│   ├── appearance_settings_screen.dart
│   └── accent_color_settings_screen.dart
└── showcase/               # Demo/example screens
    └── showcase_screen.dart
```

## Routing Convention (MANDATORY)

Every screen MUST define static route constants:

```dart
class ProfileScreen extends StatelessWidget {
  static const name = 'Profile Screen';  // Display name
  static const path = '/profile';         // GoRouter path

  const ProfileScreen({super.key});
  // ...
}
```

## Screen Template

```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/destination.dart';

class ExampleScreen extends StatelessWidget {
  static const name = 'Example Screen';
  static const path = '/example';

  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(ExampleScreen.name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: Text(context.l10n.screenTitle),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: (context) => SafeArea(
        child: Center(
          child: Text('Screen content'),
        ),
      ),
    );
  }
}
```

## Router Integration

After creating a screen, add it to `lib/router.dart`:

```dart
GoRoute(
  name: ExampleScreen.name,
  path: ExampleScreen.path,
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: const ExampleScreen(),
  ),
),
```

## Navigation Destinations

For screens in the main navigation, update `lib/destination.dart`:

```dart
static List<NavigationDestination> navs(BuildContext context) {
  return [
    // existing destinations...
    NavigationDestination(
      key: Key(ExampleScreen.name),
      icon: const Icon(Icons.example),
      label: context.l10n.example,
    ),
  ];
}
```

## Key Dependencies

```dart
import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';  // Responsive layout
import 'package:app_locale/app_locale.dart';                      // Localization
import 'package:app_artwork/app_artwork.dart';                    // Icons, animations
import 'package:flutter_app_template/destination.dart';           // Navigation
```

## Localization

Add screen text to `app_lib/locale/lib/l10n/app_en.arb`:

```json
{
  "exampleTitle": "Example",
  "@exampleTitle": {
    "description": "Title for the example screen"
  }
}
```

Then run: `melos run gen-l10n`

## Testing

Create screen tests in `test/screens/`:

```dart
testWidgets('ExampleScreen renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: ExampleScreen()),
  );
  expect(find.text('Example'), findsOneWidget);
});
```

Run tests: `flutter test test/screens/example_screen_test.dart`
