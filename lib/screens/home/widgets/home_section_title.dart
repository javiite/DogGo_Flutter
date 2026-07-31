import 'package:flutter/material.dart';

import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_theme.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const HomeSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        subtitle != null && subtitle!.trim().isNotEmpty;

    final hasAction =
        actionText != null &&
        actionText!.trim().isNotEmpty &&
        onAction != null;

    return Row(
      crossAxisAlignment: hasSubtitle
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DogGoTheme.title(
                  size: 22,
                  color: DogGoTheme.ink,
                ),
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: DogGoTheme.subtitle(size: 13),
                ),
              ],
            ],
          ),
        ),
        if (hasAction) ...[
          const SizedBox(width: 12),
          _SectionAction(
            text: actionText!,
            onTap: onAction!,
          ),
        ],
      ],
    );
  }
}

class _SectionAction extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SectionAction({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 40,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(
              DogGoRadius.button,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 12.5,
              color: DogGoTheme.teal,
              weight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}