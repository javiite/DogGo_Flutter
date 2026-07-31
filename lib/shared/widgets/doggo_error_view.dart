import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;
  final bool compact;

  const DogGoErrorView({
    super.key,
    this.title = 'Algo salió mal',
    required this.message,
    this.onRetry,
    this.retryText = 'Reintentar',
    this.icon = Icons.error_outline_rounded,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          compact
              ? DogGoSpacing.md
              : DogGoSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.redLight,
          borderRadius: BorderRadius.circular(
            DogGoRadius.large,
          ),
          border: Border.all(
            color: DogGoTheme.red.withValues(alpha: .20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 46 : 58,
              height: compact ? 46 : 58,
              decoration: const BoxDecoration(
                color: DogGoTheme.card,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: DogGoTheme.red,
                size: compact ? 24 : 30,
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
            if (onRetry != null) ...[
              const SizedBox(height: DogGoSpacing.md),
              SizedBox(
                width: compact ? null : double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: Text(retryText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}