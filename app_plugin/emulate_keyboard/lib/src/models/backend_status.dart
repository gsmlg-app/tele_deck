import 'keyboard_backend.dart';

/// Status information for a keyboard emulation backend.
class BackendStatus {
  /// The backend this status is for.
  final KeyboardBackend backend;

  /// Whether the backend is available on this device.
  final bool isAvailable;

  /// Whether the backend is currently initialized and ready.
  final bool isInitialized;

  /// Whether the backend is currently connected/active.
  final bool isConnected;

  /// Human-readable status message.
  final String message;

  /// Error message if the backend failed to initialize.
  final String? error;

  /// Additional backend-specific information.
  final Map<String, dynamic>? details;

  const BackendStatus({
    required this.backend,
    required this.isAvailable,
    this.isInitialized = false,
    this.isConnected = false,
    this.message = '',
    this.error,
    this.details,
  });

  /// Create from platform channel response.
  factory BackendStatus.fromMap(Map<String, dynamic> map) {
    final backendName = map['backend'] as String;
    final backend = KeyboardBackend.values.firstWhere(
      (b) => b.name == backendName,
      orElse: () => KeyboardBackend.virtualDevice,
    );

    return BackendStatus(
      backend: backend,
      isAvailable: map['isAvailable'] as bool? ?? false,
      isInitialized: map['isInitialized'] as bool? ?? false,
      isConnected: map['isConnected'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      error: map['error'] as String?,
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  /// Convert to map for debugging.
  Map<String, dynamic> toMap() {
    return {
      'backend': backend.name,
      'isAvailable': isAvailable,
      'isInitialized': isInitialized,
      'isConnected': isConnected,
      'message': message,
      if (error != null) 'error': error,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() {
    return 'BackendStatus(${backend.name}: available=$isAvailable, '
        'initialized=$isInitialized, connected=$isConnected, '
        'message="$message"${error != null ? ', error="$error"' : ''})';
  }
}

/// Status for all backends.
class AllBackendsStatus {
  final BackendStatus virtualDevice;
  final BackendStatus uinput;
  final BackendStatus bluetoothHid;

  /// The currently active backend, if any.
  final KeyboardBackend? activeBackend;

  const AllBackendsStatus({
    required this.virtualDevice,
    required this.uinput,
    required this.bluetoothHid,
    this.activeBackend,
  });

  /// Get status for a specific backend.
  BackendStatus operator [](KeyboardBackend backend) {
    switch (backend) {
      case KeyboardBackend.virtualDevice:
        return virtualDevice;
      case KeyboardBackend.uinput:
        return uinput;
      case KeyboardBackend.bluetoothHid:
        return bluetoothHid;
    }
  }

  /// Get list of available backends.
  List<KeyboardBackend> get availableBackends {
    return [
      if (virtualDevice.isAvailable) KeyboardBackend.virtualDevice,
      if (uinput.isAvailable) KeyboardBackend.uinput,
      if (bluetoothHid.isAvailable) KeyboardBackend.bluetoothHid,
    ];
  }

  /// Create from platform channel response.
  factory AllBackendsStatus.fromMap(Map<String, dynamic> map) {
    final activeBackendName = map['activeBackend'] as String?;
    KeyboardBackend? activeBackend;
    if (activeBackendName != null) {
      activeBackend = KeyboardBackend.values.firstWhere(
        (b) => b.name == activeBackendName,
        orElse: () => KeyboardBackend.virtualDevice,
      );
    }

    return AllBackendsStatus(
      virtualDevice: BackendStatus.fromMap(
        (map['virtualDevice'] as Map<Object?, Object?>).cast<String, dynamic>(),
      ),
      uinput: BackendStatus.fromMap(
        (map['uinput'] as Map<Object?, Object?>).cast<String, dynamic>(),
      ),
      bluetoothHid: BackendStatus.fromMap(
        (map['bluetoothHid'] as Map<Object?, Object?>).cast<String, dynamic>(),
      ),
      activeBackend: activeBackend,
    );
  }
}
