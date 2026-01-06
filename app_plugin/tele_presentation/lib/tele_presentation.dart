/// Secondary display presentation for dual-screen devices
///
/// Provides:
/// - Display detection (secondary/presentation displays)
/// - Display change events via stream
/// - Display information queries
///
/// The actual presentation rendering is done in native code using
/// the FlutterPresentation base class. Use TelePresentation for
/// display detection and event streaming from Dart.
library tele_presentation;

export 'src/tele_presentation.dart';
export 'src/models/models.dart';
