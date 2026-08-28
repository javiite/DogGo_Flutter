import 'package:flutter/material.dart';

import '../../services/app_preferences_service.dart';
import '../../theme/doggo_theme.dart';

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;

  const OnboardingStep(
    this.icon,
    this.title,
    this.description, {
    this.actionLabel,
  });
}

bool _contextualOnboardingVisible = false;

Future<void> showContextualOnboarding(
  BuildContext context, {
  required String contextKey,
  required String title,
  required List<OnboardingStep> steps,
  ValueChanged<int>? onStepAction,
  bool force = false,
}) async {
  final storageKey = '${contextKey}_v3';

  if (steps.isEmpty) return;
  if (_contextualOnboardingVisible) return;
  if (!force && await AppPreferencesService.hasSeenOnboarding(storageKey)) {
    return;
  }
  if (_contextualOnboardingVisible) return;
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;

  _contextualOnboardingVisible = true;
  var index = 0;

  try {
    final selectedStep = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      showDragHandle: true,
      barrierColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final step = steps[index];
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              22,
              8,
              22,
              22 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(step.icon, size: 54, color: DogGoTheme.teal),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.title(size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.title(size: 17),
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: DogGoTheme.subtitle(size: 13.5),
                ),
                const SizedBox(height: 22),
                if (step.actionLabel != null && onStepAction != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(sheetContext, index),
                      icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                      label: Text(step.actionLabel!),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 330;
                    final progress = Text(
                      '${index + 1}/${steps.length}',
                      style: DogGoTheme.body(
                        size: 12,
                        color: DogGoTheme.muted,
                        weight: FontWeight.w800,
                      ),
                    );
                    final skip = TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Omitir'),
                    );
                    final next = FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                      onPressed: () {
                        if (index < steps.length - 1) {
                          setSheetState(() => index++);
                        } else {
                          Navigator.pop(sheetContext);
                        }
                      },
                      child: Text(
                        index < steps.length - 1 ? 'Siguiente' : 'Entendido',
                      ),
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          progress,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: skip),
                              const SizedBox(width: 8),
                              Expanded(child: next),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        skip,
                        const Spacer(),
                        progress,
                        const Spacer(),
                        next,
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
    await AppPreferencesService.markOnboardingSeen(storageKey);
    if (selectedStep != null && context.mounted) {
      onStepAction?.call(selectedStep);
    }
  } finally {
    _contextualOnboardingVisible = false;
  }
}
