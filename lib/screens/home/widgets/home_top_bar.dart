import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../../widgets/doggo_logo.dart';

class HomeTopBar extends StatelessWidget {
  final String role;
  final bool isWalker;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final VoidCallback onMenuTap;

  const HomeTopBar({
    super.key,
    required this.role,
    required this.isWalker,
    required this.unreadNotifications,
    required this.onNotificationsTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      color: DogGoTheme.card,
      child: Row(
        children: [
          const DogGoLogo(size: 48),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWalker
                      ? Icons.directions_walk_rounded
                      : Icons.pets_rounded,
                  size: 17,
                  color: DogGoTheme.teal,
                ),
                const SizedBox(width: 7),
                Text(
                  role,
                  style: DogGoTheme.body(
                    size: 12.5,
                    color: DogGoTheme.ink,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: DogGoTheme.muted,
                ),
              ],
            ),
          ),
          const Spacer(),
          _TopBarButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: unreadNotifications,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 8),
          _TopBarButton(
            icon: Icons.menu_rounded,
            onTap: onMenuTap,
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _TopBarButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = badgeCount > 0;

    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DogGoTheme.border),
              ),
              child: Icon(
                icon,
                color: DogGoTheme.ink,
                size: 23,
              ),
            ),
            if (showBadge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.orange,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DogGoTheme.card,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}