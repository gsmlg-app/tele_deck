import 'package:bloc/bloc.dart';
import 'package:emulate_keyboard/emulate_keyboard.dart';
import 'package:tele_constants/tele_constants.dart';
import 'package:tele_services/tele_services.dart';

import 'keyboard_event.dart';
import 'keyboard_state.dart';

/// BLoC for keyboard state management
class KeyboardBloc extends Bloc<KeyboardEvent, KeyboardState> {
  final ImeChannelService _imeService;
  final EmulateKeyboard _emulateKeyboard = EmulateKeyboard();

  KeyboardBloc({required ImeChannelService imeService})
    : _imeService = imeService,
      super(KeyboardState.initial()) {
    // Register event handlers
    on<KeyboardKeyPressed>(_onKeyPressed);
    on<KeyboardBackspacePressed>(_onBackspacePressed);
    on<KeyboardEnterPressed>(_onEnterPressed);
    on<KeyboardTabPressed>(_onTabPressed);
    on<KeyboardEscapePressed>(_onEscapePressed);
    on<KeyboardDeletePressed>(_onDeletePressed);
    on<KeyboardFunctionKeyPressed>(_onFunctionKeyPressed);
    on<KeyboardMediaKeyPressed>(_onMediaKeyPressed);
    on<KeyboardArrowKeyPressed>(_onArrowKeyPressed);
    on<KeyboardShiftToggled>(_onShiftToggled);
    on<KeyboardShiftLocked>(_onShiftLocked);
    on<KeyboardCapsLockToggled>(_onCapsLockToggled);
    on<KeyboardCtrlToggled>(_onCtrlToggled);
    on<KeyboardAltToggled>(_onAltToggled);
    on<KeyboardSuperToggled>(_onSuperToggled);
    on<KeyboardFnToggled>(_onFnToggled);
    on<KeyboardModeChanged>(_onModeChanged);
    on<KeyboardModeSelectorChanged>(_onModeSelectorChanged);
    on<KeyboardConnectionChanged>(_onConnectionChanged);
    on<KeyboardDisplayModeChanged>(_onDisplayModeChanged);
    on<KeyboardTypeChanged>(_onTypeChanged);
    on<KeyboardEmulationBackendChanged>(_onEmulationBackendChanged);
    on<KeyboardEmulationInitialize>(_onEmulationInitialize);
    on<KeyboardCheckBackendAvailability>(_onCheckBackendAvailability);
    on<KeyboardSelectBackend>(_onSelectBackend);
    on<KeyboardBackendSelectionChanged>(_onBackendSelectionChanged);
    on<KeyboardVirtualKeyboardToggled>(_onVirtualKeyboardToggled);

    // Set up IME callbacks
    _imeService.onConnectionStatusChanged = (isConnected) {
      add(KeyboardConnectionChanged(isConnected));
    };
    _imeService.onDisplayModeChanged = (mode) {
      add(KeyboardDisplayModeChanged(mode));
    };
    _imeService.init();
  }

  /// Convert EmulationBackend to KeyboardBackend
  KeyboardBackend _toPluginBackend(EmulationBackend backend) {
    switch (backend) {
      case EmulationBackend.virtualDevice:
        return KeyboardBackend.virtualDevice;
      case EmulationBackend.uinput:
        return KeyboardBackend.uinput;
      case EmulationBackend.bluetoothHid:
        return KeyboardBackend.bluetoothHid;
    }
  }

  Future<void> _onKeyPressed(
    KeyboardKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    String char = event.key;

    // PHYSICAL MODE: Use EmulateKeyboard plugin for all input
    if (state.keyboardType == KeyboardType.physical) {
      if (state.isEmulationInitialized) {
        // Use emulation plugin
        final keyCode = _charToKeyCode(char.toLowerCase());
        if (keyCode != null) {
          await _emulateKeyboard.sendKeyEvent(EmulatedKeyEvent.press(
            keyCode: keyCode,
            shift: state.isShiftActive,
            ctrl: state.ctrlEnabled,
            alt: state.altEnabled,
            meta: state.superEnabled,
          ));
          // Reset one-shot modifiers
          if (state.shiftEnabled && !state.shiftLocked) {
            emit(state.copyWith(shiftEnabled: false));
          }
          if (state.ctrlEnabled || state.altEnabled) {
            emit(state.copyWith(ctrlEnabled: false, altEnabled: false));
          }
        }
      } else {
        // Fallback to IME sendKeyEvent
        final keyCode = _charToKeyCode(char.toLowerCase());
        if (keyCode != null) {
          await _imeService.sendKeyEvent(
            keyCode: keyCode,
            shift: state.isShiftActive,
            ctrl: state.ctrlEnabled,
            alt: state.altEnabled,
            meta: state.superEnabled,
          );
          // Reset one-shot modifiers
          if (state.shiftEnabled && !state.shiftLocked) {
            emit(state.copyWith(shiftEnabled: false));
          }
          if (state.ctrlEnabled || state.altEnabled) {
            emit(state.copyWith(ctrlEnabled: false, altEnabled: false));
          }
        }
      }
      return;
    }

    // IME MODE: Use commitText for regular input, sendKeyEvent for modifiers
    // If Ctrl or Alt is enabled, send as KeyEvent with modifiers
    if (state.ctrlEnabled || state.altEnabled) {
      final keyCode = _charToKeyCode(char.toLowerCase());
      if (keyCode != null) {
        await _imeService.sendKeyEvent(
          keyCode: keyCode,
          shift: state.isShiftActive,
          ctrl: state.ctrlEnabled,
          alt: state.altEnabled,
          meta: state.superEnabled,
        );
        // Reset modifiers after sending (one-shot behavior)
        emit(state.copyWith(
          ctrlEnabled: false,
          altEnabled: false,
          shiftEnabled: state.shiftLocked ? state.shiftEnabled : false,
        ));
        return;
      }
    }

    // Apply shift transformation
    if (state.isShiftActive && char.length == 1) {
      char = _applyShiftTransform(char);
    }

    await _imeService.commitText(char);

    // Reset shift after typing (unless locked)
    if (state.shiftEnabled && !state.shiftLocked) {
      emit(state.copyWith(shiftEnabled: false));
    }
  }

  /// Apply shift transformation to a character
  String _applyShiftTransform(String char) {
    // Letters: convert to uppercase
    if (char.toLowerCase() != char.toUpperCase()) {
      return char.toUpperCase();
    }
    // Special character mappings
    const shiftMap = {
      '`': '~',
      '1': '!',
      '2': '@',
      '3': '#',
      '4': '\$',
      '5': '%',
      '6': '^',
      '7': '&',
      '8': '*',
      '9': '(',
      '0': ')',
      '-': '_',
      '=': '+',
      '[': '{',
      ']': '}',
      '\\': '|',
      ';': ':',
      "'": '"',
      ',': '<',
      '.': '>',
      '/': '?',
    };
    return shiftMap[char] ?? char;
  }

  /// Map character to Android keycode
  int? _charToKeyCode(String char) {
    // Android keycodes: A=29, B=30, ..., Z=54
    if (char.length == 1) {
      final code = char.codeUnitAt(0);
      // a-z maps to KEYCODE_A (29) - KEYCODE_Z (54)
      if (code >= 97 && code <= 122) {
        return 29 + (code - 97);
      }
      // 0-9 maps to KEYCODE_0 (7) - KEYCODE_9 (16)
      if (code >= 48 && code <= 57) {
        return 7 + (code - 48);
      }
      // Common special keys
      switch (char) {
        case ' ':
          return 62; // KEYCODE_SPACE
        case '-':
          return 69; // KEYCODE_MINUS
        case '=':
          return 70; // KEYCODE_EQUALS
        case '[':
          return 71; // KEYCODE_LEFT_BRACKET
        case ']':
          return 72; // KEYCODE_RIGHT_BRACKET
        case '\\':
          return 73; // KEYCODE_BACKSLASH
        case ';':
          return 74; // KEYCODE_SEMICOLON
        case '\'':
          return 75; // KEYCODE_APOSTROPHE
        case '/':
          return 76; // KEYCODE_SLASH
        case ',':
          return 55; // KEYCODE_COMMA
        case '.':
          return 56; // KEYCODE_PERIOD
        case '`':
          return 68; // KEYCODE_GRAVE
      }
    }
    return null;
  }

  Future<void> _onBackspacePressed(
    KeyboardBackspacePressed event,
    Emitter<KeyboardState> emit,
  ) async {
    await _imeService.backspace();
  }

  Future<void> _onEnterPressed(
    KeyboardEnterPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    await _imeService.enter();
  }

  Future<void> _onTabPressed(
    KeyboardTabPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    await _imeService.tab();
  }

  Future<void> _onEscapePressed(
    KeyboardEscapePressed event,
    Emitter<KeyboardState> emit,
  ) async {
    // KEYCODE_ESCAPE = 111
    await _imeService.sendKeyEvent(
      keyCode: 111,
      shift: state.isShiftActive,
      ctrl: state.ctrlEnabled,
      alt: state.altEnabled,
      meta: state.superEnabled,
    );
  }

  Future<void> _onDeletePressed(
    KeyboardDeletePressed event,
    Emitter<KeyboardState> emit,
  ) async {
    await _imeService.delete();
  }

  Future<void> _onFunctionKeyPressed(
    KeyboardFunctionKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    // F1 = KEYCODE_F1 (131), F2 = 132, etc.
    final keyCode = 130 + event.number;
    await _imeService.sendKeyEvent(
      keyCode: keyCode,
      shift: state.isShiftActive,
      ctrl: state.ctrlEnabled,
      alt: state.altEnabled,
      meta: state.superEnabled,
    );
  }

  Future<void> _onMediaKeyPressed(
    KeyboardMediaKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    // Send media action name to native
    await _imeService.sendMediaKey(event.action.name);
  }

  Future<void> _onArrowKeyPressed(
    KeyboardArrowKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    // Android DPAD keycodes
    // KEYCODE_DPAD_LEFT = 21, KEYCODE_DPAD_RIGHT = 22
    // KEYCODE_DPAD_UP = 19, KEYCODE_DPAD_DOWN = 20
    int keyCode;
    switch (event.direction) {
      case ArrowDirection.left:
        keyCode = 21; // KEYCODE_DPAD_LEFT
        break;
      case ArrowDirection.right:
        keyCode = 22; // KEYCODE_DPAD_RIGHT
        break;
      case ArrowDirection.up:
        keyCode = 19; // KEYCODE_DPAD_UP
        break;
      case ArrowDirection.down:
        keyCode = 20; // KEYCODE_DPAD_DOWN
        break;
    }
    await _imeService.sendKeyEvent(
      keyCode: keyCode,
      shift: state.isShiftActive,
      ctrl: state.ctrlEnabled,
      alt: state.altEnabled,
      meta: state.superEnabled,
    );
  }

  void _onShiftToggled(
    KeyboardShiftToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(shiftEnabled: event.enabled));
  }

  void _onShiftLocked(KeyboardShiftLocked event, Emitter<KeyboardState> emit) {
    emit(state.copyWith(shiftLocked: event.locked, shiftEnabled: event.locked));
  }

  void _onCapsLockToggled(
    KeyboardCapsLockToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(capsLockEnabled: event.enabled));
  }

  void _onCtrlToggled(KeyboardCtrlToggled event, Emitter<KeyboardState> emit) {
    emit(state.copyWith(ctrlEnabled: event.enabled));
  }

  void _onAltToggled(KeyboardAltToggled event, Emitter<KeyboardState> emit) {
    emit(state.copyWith(altEnabled: event.enabled));
  }

  void _onSuperToggled(
    KeyboardSuperToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(superEnabled: event.enabled));
  }

  void _onFnToggled(KeyboardFnToggled event, Emitter<KeyboardState> emit) {
    emit(state.copyWith(fnEnabled: event.enabled));
  }

  void _onModeChanged(KeyboardModeChanged event, Emitter<KeyboardState> emit) {
    emit(state.copyWith(mode: event.mode, showModeSelector: false));
  }

  void _onModeSelectorChanged(
    KeyboardModeSelectorChanged event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(showModeSelector: event.visible));
  }

  void _onConnectionChanged(
    KeyboardConnectionChanged event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(isConnected: event.isConnected));
  }

  void _onDisplayModeChanged(
    KeyboardDisplayModeChanged event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(displayMode: event.displayMode));
  }

  void _onTypeChanged(
    KeyboardTypeChanged event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(keyboardType: event.type));
    // If switching to physical mode, try to initialize emulation
    if (event.type == KeyboardType.physical && !state.isEmulationInitialized) {
      add(const KeyboardEmulationInitialize());
    }
  }

  Future<void> _onEmulationBackendChanged(
    KeyboardEmulationBackendChanged event,
    Emitter<KeyboardState> emit,
  ) async {
    // Cleanup previous backend
    if (state.isEmulationInitialized) {
      await _emulateKeyboard.dispose();
    }

    emit(state.copyWith(
      emulationBackend: event.backend,
      isEmulationInitialized: false,
      emulationStatus: 'Backend changed to ${event.backend.displayName}',
    ));

    // If in physical mode, initialize the new backend
    if (state.keyboardType == KeyboardType.physical) {
      add(const KeyboardEmulationInitialize());
    }
  }

  Future<void> _onEmulationInitialize(
    KeyboardEmulationInitialize event,
    Emitter<KeyboardState> emit,
  ) async {
    final backend = _toPluginBackend(state.emulationBackend);

    emit(state.copyWith(
      emulationStatus: 'Initializing ${state.emulationBackend.displayName}...',
    ));

    try {
      // Check if backend is available
      final isAvailable = await _emulateKeyboard.isBackendAvailable(backend);
      if (!isAvailable) {
        emit(state.copyWith(
          isEmulationInitialized: false,
          emulationStatus: '${state.emulationBackend.displayName} not available',
        ));
        return;
      }

      // Initialize the backend
      final success = await _emulateKeyboard.initialize(backend);
      if (success) {
        emit(state.copyWith(
          isEmulationInitialized: true,
          emulationStatus: '${state.emulationBackend.displayName} ready',
        ));
      } else {
        emit(state.copyWith(
          isEmulationInitialized: false,
          emulationStatus: 'Failed to initialize ${state.emulationBackend.displayName}',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isEmulationInitialized: false,
        emulationStatus: 'Error: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCheckBackendAvailability(
    KeyboardCheckBackendAvailability event,
    Emitter<KeyboardState> emit,
  ) async {
    switch (event.backend) {
      case EmulationBackend.virtualDevice:
        emit(state.copyWith(
          virtualDeviceAvailability: BackendAvailability.checking,
          virtualDeviceStatus: 'Checking...',
        ));
        try {
          final isAvailable = await _emulateKeyboard.isBackendAvailable(
            KeyboardBackend.virtualDevice,
          ).catchError((_) => false);
          emit(state.copyWith(
            virtualDeviceAvailability: (isAvailable == true)
                ? BackendAvailability.available
                : BackendAvailability.unavailable,
            virtualDeviceStatus: (isAvailable == true)
                ? 'Available'
                : 'Not available (requires Android 14+)',
          ));
        } catch (e) {
          emit(state.copyWith(
            virtualDeviceAvailability: BackendAvailability.unavailable,
            virtualDeviceStatus: 'Error: ${e.toString()}',
          ));
        }
        break;

      case EmulationBackend.uinput:
        emit(state.copyWith(
          uinputAvailability: BackendAvailability.checking,
          uinputStatus: 'Checking root access...',
        ));
        try {
          final hasRoot = await _emulateKeyboard.checkRootAccess()
              .catchError((_) => false);
          if (hasRoot == true) {
            emit(state.copyWith(
              uinputAvailability: BackendAvailability.available,
              uinputStatus: 'Root access granted',
            ));
          } else {
            // Try to request root access
            emit(state.copyWith(
              uinputStatus: 'Requesting root access...',
            ));
            final granted = await _emulateKeyboard.requestRootAccess()
                .catchError((_) => false);
            emit(state.copyWith(
              uinputAvailability: (granted == true)
                  ? BackendAvailability.available
                  : BackendAvailability.unavailable,
              uinputStatus: (granted == true)
                  ? 'Root access granted'
                  : 'Root access denied',
            ));
          }
        } catch (e) {
          emit(state.copyWith(
            uinputAvailability: BackendAvailability.unavailable,
            uinputStatus: 'Error: ${e.toString()}',
          ));
        }
        break;

      case EmulationBackend.bluetoothHid:
        emit(state.copyWith(
          bluetoothHidAvailability: BackendAvailability.checking,
          bluetoothHidStatus: 'Checking Bluetooth...',
        ));
        try {
          final isAvailable = await _emulateKeyboard.isBackendAvailable(
            KeyboardBackend.bluetoothHid,
          ).catchError((_) => false);
          emit(state.copyWith(
            bluetoothHidAvailability: (isAvailable == true)
                ? BackendAvailability.available
                : BackendAvailability.unavailable,
            bluetoothHidStatus: (isAvailable == true)
                ? 'Available'
                : 'Not available (requires Android 9+)',
          ));
        } catch (e) {
          emit(state.copyWith(
            bluetoothHidAvailability: BackendAvailability.unavailable,
            bluetoothHidStatus: 'Error: ${e.toString()}',
          ));
        }
        break;
    }
  }

  Future<void> _onSelectBackend(
    KeyboardSelectBackend event,
    Emitter<KeyboardState> emit,
  ) async {
    // Set the backend and hide selection screen
    emit(state.copyWith(
      emulationBackend: event.backend,
      showBackendSelection: false,
      isEmulationInitialized: false,
      emulationStatus: 'Initializing...',
    ));

    // Initialize the backend
    add(const KeyboardEmulationInitialize());
  }

  void _onBackendSelectionChanged(
    KeyboardBackendSelectionChanged event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(showBackendSelection: event.visible));
  }

  void _onVirtualKeyboardToggled(
    KeyboardVirtualKeyboardToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(showVirtualKeyboard: !state.showVirtualKeyboard));
  }

  @override
  Future<void> close() {
    _imeService.dispose();
    _emulateKeyboard.dispose();
    return super.close();
  }
}
