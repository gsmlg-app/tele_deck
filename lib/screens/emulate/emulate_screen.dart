import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keyboard_bloc/keyboard_bloc.dart';
import 'package:settings_bloc/settings_bloc.dart';
import 'package:tele_constants/tele_constants.dart';
import 'package:tele_theme/tele_theme.dart';

import 'fullscreen_keyboard_screen.dart';

/// Hardware keyboard emulator screen
class EmulateScreen extends StatefulWidget {
  static const name = 'Emulate';

  const EmulateScreen({super.key});

  @override
  State<EmulateScreen> createState() => _EmulateScreenState();
}

class _EmulateScreenState extends State<EmulateScreen> {
  bool _isConfigOpen = false;

  void _openKeyboard() {
    context.push(FullscreenKeyboardScreen.path);
  }

  void _openConfig() {
    setState(() => _isConfigOpen = true);
  }

  void _closeConfig() {
    setState(() => _isConfigOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        if (previous.status != SettingsStatus.success &&
            current.status == SettingsStatus.success) {
          return true;
        }
        if (previous.status == SettingsStatus.success &&
            current.status == SettingsStatus.success &&
            previous.settings.keyboardType != current.settings.keyboardType) {
          return true;
        }
        return false;
      },
      listener: (context, settingsState) {
        if (settingsState.status == SettingsStatus.success) {
          context.read<KeyboardBloc>().add(
                KeyboardTypeChanged(settingsState.settings.keyboardType),
              );
        }
      },
      child: Stack(
        children: [
          // Main menu
          _EmulateMenuView(
            onOpenKeyboard: _openKeyboard,
            onOpenConfig: _openConfig,
          ),
          // Keyboard config overlay
          if (_isConfigOpen)
            _BackendConfigView(onClose: _closeConfig),
        ],
      ),
    );
  }
}

/// Main menu view with Open Keyboard and Config options
class _EmulateMenuView extends StatelessWidget {
  final VoidCallback onOpenKeyboard;
  final VoidCallback onOpenConfig;

  const _EmulateMenuView({
    required this.onOpenKeyboard,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(TeleDeckColors.neonCyan),
                    Color(TeleDeckColors.neonMagenta),
                  ],
                ).createShader(bounds),
                child: Text(
                  'EMULATOR',
                  style: GoogleFonts.robotoMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hardware keyboard emulator',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: const Color(TeleDeckColors.textPrimary)
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              // Open Keyboard button (always enabled)
              _MenuButton(
                title: 'Open Keyboard',
                subtitle: 'Launch emulated hardware keyboard',
                icon: Icons.keyboard,
                onTap: onOpenKeyboard,
                accentColor: const Color(TeleDeckColors.neonCyan),
              ),
              const SizedBox(height: 16),
              // Keyboard Config button
              BlocBuilder<KeyboardBloc, KeyboardState>(
                builder: (context, state) {
                  final backendName = _getBackendName(state.emulationBackend);
                  final isConfigured = state.isEmulationInitialized;
                  return _MenuButton(
                    title: 'Keyboard Config',
                    subtitle: isConfigured
                        ? 'Backend: $backendName'
                        : 'Select emulation backend',
                    icon: Icons.settings,
                    onTap: onOpenConfig,
                    accentColor: const Color(TeleDeckColors.neonMagenta),
                    badge: isConfigured ? null : 'SETUP',
                  );
                },
              ),
              const SizedBox(height: 32),
              // Status card
              BlocBuilder<KeyboardBloc, KeyboardState>(
                builder: (context, state) {
                  return _StatusCard(state: state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBackendName(EmulationBackend backend) {
    switch (backend) {
      case EmulationBackend.virtualDevice:
        return 'VirtualDeviceManager';
      case EmulationBackend.uinput:
        return 'uinput';
      case EmulationBackend.bluetoothHid:
        return 'Bluetooth HID';
    }
  }
}

/// Menu button widget
class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accentColor;
  final String? badge;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    required this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(TeleDeckColors.secondaryBackground),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(TeleDeckColors.textPrimary),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: GoogleFonts.robotoMono(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: const Color(TeleDeckColors.textPrimary)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: accentColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Status card showing current backend status
class _StatusCard extends StatelessWidget {
  final KeyboardState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(TeleDeckColors.secondaryBackground),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.5),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Backend',
            value: state.isEmulationInitialized
                ? _getBackendShortName(state.emulationBackend)
                : 'Not configured',
            color: state.isEmulationInitialized
                ? const Color(TeleDeckColors.neonCyan)
                : Colors.orange,
          ),
          const SizedBox(height: 8),
          _StatusRow(
            label: 'Status',
            value: state.isEmulationInitialized ? 'Ready' : 'Setup required',
            color: state.isEmulationInitialized ? Colors.green : Colors.orange,
          ),
          if (state.emulationStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              state.emulationStatus,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: const Color(TeleDeckColors.textPrimary)
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getBackendShortName(EmulationBackend backend) {
    switch (backend) {
      case EmulationBackend.virtualDevice:
        return 'VDM';
      case EmulationBackend.uinput:
        return 'uinput';
      case EmulationBackend.bluetoothHid:
        return 'BT HID';
    }
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color:
                const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.7),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

/// Backend configuration view
class _BackendConfigView extends StatelessWidget {
  final VoidCallback onClose;

  const _BackendConfigView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(TeleDeckColors.darkBackground),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(TeleDeckColors.neonMagenta)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(TeleDeckColors.neonCyan),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(TeleDeckColors.neonCyan),
                        Color(TeleDeckColors.neonMagenta),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'KEYBOARD CONFIG',
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Backend selection content
            Expanded(
              child: BlocBuilder<KeyboardBloc, KeyboardState>(
                builder: (context, state) {
                  return _BackendSelectionContent(
                    state: state,
                    onClose: onClose,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Backend selection content
class _BackendSelectionContent extends StatelessWidget {
  final KeyboardState state;
  final VoidCallback onClose;

  const _BackendSelectionContent({
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select how to emulate keyboard input',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color:
                  const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // Backend options
          Expanded(
            child: Column(
              children: [
                _BackendOptionCard(
                  title: 'VirtualDeviceManager',
                  description: 'Android 14+ API. Official system method.',
                  icon: Icons.smartphone,
                  availability: state.virtualDeviceAvailability,
                  statusMessage: state.virtualDeviceStatus,
                  isSelected:
                      state.emulationBackend == EmulationBackend.virtualDevice &&
                          state.isEmulationInitialized,
                  onCheck: () => context.read<KeyboardBloc>().add(
                        const KeyboardCheckBackendAvailability(
                          EmulationBackend.virtualDevice,
                        ),
                      ),
                  onSelect: state.virtualDeviceAvailability ==
                          BackendAvailability.available
                      ? () {
                          context.read<KeyboardBloc>().add(
                                const KeyboardSelectBackend(
                                  EmulationBackend.virtualDevice,
                                ),
                              );
                          onClose();
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                _BackendOptionCard(
                  title: 'uinput',
                  description: 'Kernel-level input. Requires root access.',
                  icon: Icons.terminal,
                  availability: state.uinputAvailability,
                  statusMessage: state.uinputStatus,
                  isSelected: state.emulationBackend == EmulationBackend.uinput &&
                      state.isEmulationInitialized,
                  onCheck: () => context.read<KeyboardBloc>().add(
                        const KeyboardCheckBackendAvailability(
                          EmulationBackend.uinput,
                        ),
                      ),
                  onSelect:
                      state.uinputAvailability == BackendAvailability.available
                          ? () {
                              context.read<KeyboardBloc>().add(
                                    const KeyboardSelectBackend(
                                      EmulationBackend.uinput,
                                    ),
                                  );
                              onClose();
                            }
                          : null,
                ),
                const SizedBox(height: 12),
                _BackendOptionCard(
                  title: 'Bluetooth HID',
                  description: 'Bluetooth keyboard emulation.',
                  icon: Icons.bluetooth,
                  availability: state.bluetoothHidAvailability,
                  statusMessage: state.bluetoothHidStatus,
                  isSelected:
                      state.emulationBackend == EmulationBackend.bluetoothHid &&
                          state.isEmulationInitialized,
                  onCheck: () => context.read<KeyboardBloc>().add(
                        const KeyboardCheckBackendAvailability(
                          EmulationBackend.bluetoothHid,
                        ),
                      ),
                  onSelect: state.bluetoothHidAvailability ==
                          BackendAvailability.available
                      ? () {
                          context.read<KeyboardBloc>().add(
                                const KeyboardSelectBackend(
                                  EmulationBackend.bluetoothHid,
                                ),
                              );
                          onClose();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a backend option
class _BackendOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final BackendAvailability availability;
  final String statusMessage;
  final bool isSelected;
  final VoidCallback? onCheck;
  final VoidCallback? onSelect;

  const _BackendOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.availability,
    required this.statusMessage,
    required this.isSelected,
    this.onCheck,
    this.onSelect,
  });

  Color _getStatusColor() {
    if (isSelected) return const Color(TeleDeckColors.neonCyan);
    switch (availability) {
      case BackendAvailability.unknown:
        return const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.6);
      case BackendAvailability.checking:
        return const Color(TeleDeckColors.neonCyan);
      case BackendAvailability.available:
        return Colors.green;
      case BackendAvailability.unavailable:
        return Colors.red;
      case BackendAvailability.disabled:
        return const Color(TeleDeckColors.textPrimary).withValues(alpha: 0.3);
    }
  }

  String _getStatusText() {
    if (isSelected) return 'Selected';
    switch (availability) {
      case BackendAvailability.unknown:
        return 'Tap to check';
      case BackendAvailability.checking:
        return 'Checking...';
      case BackendAvailability.available:
        return 'Available';
      case BackendAvailability.unavailable:
        return 'Unavailable';
      case BackendAvailability.disabled:
        return 'Disabled';
    }
  }

  IconData _getStatusIcon() {
    if (isSelected) return Icons.check_circle;
    switch (availability) {
      case BackendAvailability.unknown:
        return Icons.help_outline;
      case BackendAvailability.checking:
        return Icons.sync;
      case BackendAvailability.available:
        return Icons.check_circle_outline;
      case BackendAvailability.unavailable:
        return Icons.cancel;
      case BackendAvailability.disabled:
        return Icons.block;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = availability == BackendAvailability.available;
    final isChecking = availability == BackendAvailability.checking;
    final borderColor = isSelected
        ? const Color(TeleDeckColors.neonCyan)
        : isAvailable
            ? Colors.green.withValues(alpha: 0.5)
            : const Color(TeleDeckColors.neonCyan).withValues(alpha: 0.3);

    return Expanded(
      child: GestureDetector(
        onTap: isSelected
            ? null
            : (isAvailable ? onSelect : (isChecking ? null : onCheck)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(TeleDeckColors.secondaryBackground),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(TeleDeckColors.neonCyan)
                          .withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isSelected
                          ? const Color(TeleDeckColors.neonCyan)
                          : const Color(TeleDeckColors.neonCyan))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? const Color(TeleDeckColors.neonCyan)
                      : const Color(TeleDeckColors.neonCyan),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(TeleDeckColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        color: const Color(TeleDeckColors.textPrimary)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    if (statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        statusMessage,
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          color: _getStatusColor(),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusText(),
                    style: GoogleFonts.robotoMono(
                      fontSize: 8,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
