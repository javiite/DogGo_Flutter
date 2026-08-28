import 'package:flutter/material.dart';

import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoStickyActionBar extends StatelessWidget {
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final IconData? secondaryIcon;
  final VoidCallback? onSecondary;

  const DogGoStickyActionBar({
    super.key,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.secondaryIcon,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DogGoSpacing.screenHorizontal,
            DogGoSpacing.compactGap,
            DogGoSpacing.screenHorizontal,
            DogGoSpacing.compactGap,
          ),
          child: Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: onSecondary,
                      icon: Icon(secondaryIcon ?? Icons.edit_outlined),
                      label: Text(secondaryLabel!),
                    ),
                  ),
                ),
                const SizedBox(width: DogGoSpacing.compactGap),
              ],
              Expanded(
                flex: secondaryLabel == null ? 1 : 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onPrimary,
                    icon: Icon(primaryIcon),
                    label: Text(primaryLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
