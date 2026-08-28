import 'package:flutter/material.dart';

import '../../theme/doggo_radius.dart';
import '../../theme/doggo_spacing.dart';
import '../../theme/doggo_theme.dart';

class DogGoSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Color iconColor;
  final Color iconBackground;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const DogGoSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.iconColor = DogGoTheme.teal,
    this.iconBackground = DogGoTheme.tealLight,
    this.trailing,
    this.padding = const EdgeInsets.all(DogGoSpacing.cardPadding),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 17)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: DogGoTheme.subtitle(size: 12.5)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: DogGoSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: DogGoSpacing.largeGap),
          child,
        ],
      ),
    );
  }
}
