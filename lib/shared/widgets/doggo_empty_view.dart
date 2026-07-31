import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoEmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Color color;
  final Color background;
  final bool compact;

  const DogGoEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
    this.color = DogGoTheme.teal,
    this.background = DogGoTheme.tealLight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction =
        actionText != null &&
        actionText!.trim().isNotEmpty &&
        onAction != null;

    return Semantics(
      container: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          compact
              ? DogGoSpacing.md
              : DogGoSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(
            DogGoRadius.large,
          ),
          border: Border.all(color: DogGoTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 48 : 62,
              height: compact ? 48 : 62,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(
                  DogGoRadius.medium,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: compact ? 25 : 31,
              ),
            ),
            const SizedBox(height: DogGoSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: DogGoTheme.title(
                size: compact ? 17 : 20,
              ),
            ),
            const SizedBox(height: DogGoSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: DogGoTheme.subtitle(
                size: compact ? 12 : 13,
              ),
            ),
            if (hasAction) ...[
              const SizedBox(height: DogGoSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionText!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}