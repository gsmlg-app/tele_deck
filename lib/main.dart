import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:setup_bloc/setup_bloc.dart';
import 'package:tele_deck/app.dart';
import 'package:tele_services/tele_services.dart';
import 'package:tele_theme/tele_theme.dart';

// Export imeMain entry point to ensure it's included in the AOT build
export 'main_ime.dart' show imeMain;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI for immersive dark experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(TeleDeckColors.darkBackground),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize services
  final imeChannelService = ImeChannelService();
  imeChannelService.init();

  final settingsService = SettingsService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) =>
              SettingsBloc(settingsService: settingsService)..add(const SettingsLoaded()),
        ),
        BlocProvider<SetupBloc>(
          create: (context) =>
              SetupBloc(imeService: imeChannelService)..add(const SetupCheckRequested()),
        ),
      ],
      child: TeleDeckLauncherApp(imeChannelService: imeChannelService),
    ),
  );
}
