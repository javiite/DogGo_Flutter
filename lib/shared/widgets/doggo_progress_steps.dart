import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoProgressSteps extends StatelessWidget {
  final int current;
  final int total;
  final String label;
  final bool onDarkBackground;

  const DogGoProgressSteps({
    super.key,
    required this.current,
    required this.total,
    required this.label,
    this.onDarkBackground = false,
  }) : assert(current > 0 && total > 0 && current <= total);

  @override
  Widget build(BuildContext context) {
    final foreground = onDarkBackground ? Colors.white : DogGoTheme.teal;
    final inactive = onDarkBackground
        ? Colors.white.withValues(alpha: .22)
        : DogGoTheme.divider;

    return Semantics(
      label: '$label. Paso $current de $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: DogGoTheme.label(size: 10.5, color: foreground),
                ),
              ),
              Text(
                '$current de $total',
                style: DogGoTheme.body(
                  size: 11,
                  color: foreground,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(DogGoRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: current / total,
              color: foreground,
              backgroundColor: inactive,
            ),
          ),
        ],
      ),
    );
  }
}
