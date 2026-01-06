// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_services/tele_services.dart';

import 'package:tele_deck/app.dart';

void main() {
  testWidgets('TeleDeck launcher app smoke test', (WidgetTester tester) async {
    // Create test services
    final imeChannelService = ImeChannelService();
    final settingsService = SettingsService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>(
            create: (context) =>
                SettingsBloc(settingsService: settingsService)
                  ..add(const SettingsLoaded()),
          ),
          BlocProvider<SetupBloc>(
            create: (context) =>
                SetupBloc(imeService: imeChannelService)
                  ..add(const SetupCheckRequested()),
          ),
        ],
        child: TeleDeckLauncherApp(imeChannelService: imeChannelService),
      ),
    );

    // Wait for the async setup to complete
    await tester.pump();

    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
