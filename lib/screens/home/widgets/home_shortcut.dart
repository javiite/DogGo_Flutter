import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const HomeShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = DogGoTheme.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 84,
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: DogGoTheme.body(
                      size: 11,
                      color: DogGoTheme.ink,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}