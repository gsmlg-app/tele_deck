import 'package:bloc/bloc.dart';
import 'package:tele_lib/tele_lib.dart';

import 'keyboard_event.dart';
import 'keyboard_state.dart';

/// BLoC for keyboard state management
class KeyboardBloc extends Bloc<KeyboardEvent, KeyboardState> {
  final ImeChannelService _imeService;

  KeyboardBloc({
    required ImeChannelService imeService,
  })  : _imeService = imeService,
        super(KeyboardState.initial()) {
    // Register event handlers
    on<KeyboardKeyPressed>(_onKeyPressed);
    on<KeyboardBackspacePressed>(_onBackspacePressed);
    on<KeyboardEnterPressed>(_onEnterPressed);
    on<KeyboardTabPressed>(_onTabPressed);
    on<KeyboardEscapePressed>(_onEscapePressed);
    on<KeyboardDeletePressed>(_onDeletePressed);
    on<KeyboardFunctionKeyPressed>(_onFunctionKeyPressed);
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

    // Set up IME callbacks
    _imeService.onConnectionStatusChanged = (isConnected) {
      add(KeyboardConnectionChanged(isConnected));
    };
    _imeService.onDisplayModeChanged = (mode) {
      add(KeyboardDisplayModeChanged(mode));
    };
    _imeService.init();
  }

  Future<void> _onKeyPressed(
    KeyboardKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    String char = event.key;

    // Apply shift transformation for letters
    if (state.isShiftActive && char.length == 1) {
      char = char.toUpperCase();
    }

    await _imeService.commitText(char);

    // Reset shift after typing (unless locked)
    if (state.shiftEnabled && !state.shiftLocked) {
      emit(state.copyWith(shiftEnabled: false));
    }
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
    await _imeService.sendKeyEvent(keyCode: 111);
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
    await _imeService.sendKeyEvent(keyCode: keyCode);
  }

  Future<void> _onArrowKeyPressed(
    KeyboardArrowKeyPressed event,
    Emitter<KeyboardState> emit,
  ) async {
    int offset;
    switch (event.direction) {
      case ArrowDirection.left:
        offset = -1;
        break;
      case ArrowDirection.right:
        offset = 1;
        break;
      case ArrowDirection.up:
        offset = -100; // Special value for up
        break;
      case ArrowDirection.down:
        offset = 100; // Special value for down
        break;
    }
    await _imeService.moveCursor(offset);
  }

  void _onShiftToggled(
    KeyboardShiftToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(shiftEnabled: event.enabled));
  }

  void _onShiftLocked(
    KeyboardShiftLocked event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(
      shiftLocked: event.locked,
      shiftEnabled: event.locked,
    ));
  }

  void _onCapsLockToggled(
    KeyboardCapsLockToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(capsLockEnabled: event.enabled));
  }

  void _onCtrlToggled(
    KeyboardCtrlToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(ctrlEnabled: event.enabled));
  }

  void _onAltToggled(
    KeyboardAltToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(altEnabled: event.enabled));
  }

  void _onSuperToggled(
    KeyboardSuperToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(superEnabled: event.enabled));
  }

  void _onFnToggled(
    KeyboardFnToggled event,
    Emitter<KeyboardState> emit,
  ) {
    emit(state.copyWith(fnEnabled: event.enabled));
  }

  void _onModeChanged(
    KeyboardModeChanged event,
    Emitter<KeyboardState> emit,
  ) {
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

  @override
  Future<void> close() {
    _imeService.dispose();
    return super.close();
  }
}
