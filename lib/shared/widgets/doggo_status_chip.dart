import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_theme.dart';

enum DogGoStatusTone { positive, attention, neutral }

class DogGoStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final DogGoStatusTone tone;

  const DogGoStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = DogGoStatusTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      DogGoStatusTone.positive => (DogGoTheme.teal, DogGoTheme.tealLight),
      DogGoStatusTone.attention => (DogGoTheme.orange, DogGoTheme.orangeLight),
      DogGoStatusTone.neutral => (DogGoTheme.muted, DogGoTheme.cream2),
    };

    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(DogGoRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(
                size: 11.5,
                color: foreground,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
