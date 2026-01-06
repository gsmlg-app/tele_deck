import 'dart:async';

import 'package:flutter/services.dart';

import 'models/models.dart';

export 'models/models.dart';

/// Secondary display detection and management service
///
/// Provides functionality to detect secondary displays and listen for
/// display connection/disconnection events.
///
/// Note: The actual presentation rendering is done in native code
/// using the FlutterPresentation base class. This Dart API provides
/// display detection and event streaming.
class TelePresentation {
  TelePresentation._();

  static final TelePresentation _instance = TelePresentation._();

  /// Returns the singleton instance of [TelePresentation]
  static TelePresentation get instance => _instance;

  /// Method channel for platform communication
  static const MethodChannel _channel = MethodChannel('tele_presentation');

  /// Event channel for display change events
  static const EventChannel _eventChannel =
      EventChannel('tele_presentation/events');

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<DisplayEvent> _displayEventController =
      StreamController<DisplayEvent>.broadcast();

  /// Stream of display change events
  Stream<DisplayEvent> get displayEvents => _displayEventController.stream;

  /// Check if a secondary display is available
  Future<bool> hasSecondaryDisplay() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasSecondaryDisplay');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to check secondary display: ${e.message}');
      return false;
    }
  }

  /// Get the secondary display info
  ///
  /// Returns null if no secondary display is available
  Future<DisplayInfo?> getSecondaryDisplay() async {
    try {
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('getSecondaryDisplay');
      if (result == null) return null;
      return DisplayInfo.fromMap(result);
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get secondary display: ${e.message}');
      return null;
    }
  }

  /// Get all connected displays
  Future<List<DisplayInfo>> getAllDisplays() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getAllDisplays');
      if (result == null) return [];
      return result
          .map((e) => DisplayInfo.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get all displays: ${e.message}');
      return [];
    }
  }

  /// Get all presentation-capable displays (excludes primary)
  Future<List<DisplayInfo>> getPresentationDisplays() async {
    try {
      final result =
          await _channel.invokeMethod<List<dynamic>>('getPresentationDisplays');
      if (result == null) return [];
      return result
          .map((e) => DisplayInfo.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get presentation displays: ${e.message}');
      return [];
    }
  }

  /// Get information about a specific display
  Future<DisplayInfo?> getDisplayInfo(int displayId) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDisplayInfo',
        {'displayId': displayId},
      );
      if (result == null) return null;
      return DisplayInfo.fromMap(result);
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Failed to get display info: ${e.message}');
      return null;
    }
  }

  /// Start listening for display change events
  void startListening() {
    if (_eventSubscription != null) return;

    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final displayEvent = DisplayEvent.fromMap(event);
          _displayEventController.add(displayEvent);
        }
      },
      onError: (error) {
        // ignore: avoid_print
        print('Display event error: $error');
      },
    );
  }

  /// Stop listening for display change events
  void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _displayEventController.close();
  }
}
