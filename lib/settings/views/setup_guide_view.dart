import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_provider.dart';
import '../setup_guide_state.dart';

/// Setup guide widget with 3-step onboarding flow
class SetupGuideView extends ConsumerWidget {
  final VoidCallback? onComplete;

  const SetupGuideView({
    super.key,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupStateAsync = ref.watch(setupGuideProvider);

    return setupStateAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (setupState) => _buildContent(context, ref, setupState),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, SetupGuideState setupState) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App title
              const Text(
                'TeleDeck',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Dual-Screen Keyboard',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Step indicator
              _StepIndicator(currentStep: setupState.currentStep),
              const SizedBox(height: 32),

              // Step content
              Expanded(
                child: _StepContent(
                  state: setupState,
                  onAction: () => _handleAction(context, ref, setupState),
                ),
              ),

              // Status indicators
              _StatusRow(
                label: 'Keyboard Enabled',
                isComplete: setupState.imeEnabled,
              ),
              const SizedBox(height: 8),
              _StatusRow(
                label: 'Keyboard Active',
                isComplete: setupState.imeActive,
              ),
              const SizedBox(height: 24),

              // Refresh button
              TextButton.icon(
                onPressed: () => ref.invalidate(setupGuideProvider),
                icon: const Icon(Icons.refresh, color: Colors.white54),
                label: const Text(
                  'Refresh Status',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, SetupGuideState state) {
    final settingsNotifier = ref.read(settingsProvider.notifier);

    switch (state.currentStep) {
      case 1:
        settingsNotifier.openImeSettings();
        break;
      case 2:
        settingsNotifier.openImePicker();
        break;
      case 3:
        onComplete?.call();
        break;
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final stepNum = index + 1;
        final isActive = stepNum == currentStep;
        final isComplete = stepNum < currentStep;

        return Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete
                    ? Colors.green
                    : isActive
                        ? Colors.blue
                        : Colors.grey.shade700,
                border: isActive
                    ? Border.all(color: Colors.blue.shade300, width: 2)
                    : null,
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '$stepNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: isComplete ? Colors.green : Colors.grey.shade700,
              ),
          ],
        );
      }),
    );
  }
}

class _StepContent extends StatelessWidget {
  final SetupGuideState state;
  final VoidCallback onAction;

  const _StepContent({
    required this.state,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getStepIcon(),
          size: 80,
          color: state.isComplete ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 24),
        Text(
          state.stepTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          state.stepDescription,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isComplete ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            state.actionButtonText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  IconData _getStepIcon() {
    switch (state.currentStep) {
      case 1:
        return Icons.settings;
      case 2:
        return Icons.keyboard;
      case 3:
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isComplete;

  const _StatusRow({
    required this.label,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.circle_outlined,
          color: isComplete ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isComplete ? Colors.white : Colors.white54,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          isComplete ? 'Done' : 'Pending',
          style: TextStyle(
            color: isComplete ? Colors.green : Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
