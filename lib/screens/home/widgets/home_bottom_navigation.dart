import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';

class HomeBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final String thirdLabel;
  final IconData thirdIcon;
  final String fourthLabel;
  final IconData fourthIcon;
  final VoidCallback onHome;
  final VoidCallback onAgenda;
  final VoidCallback onThird;
  final VoidCallback onFourth;

  const HomeBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.thirdLabel,
    required this.thirdIcon,
    required this.fourthLabel,
    required this.fourthIcon,
    required this.onHome,
    required this.onAgenda,
    required this.onThird,
    required this.onFourth,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          border: const Border(
            top: BorderSide(color: DogGoTheme.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.035),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavigationItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                active: currentIndex == 0,
                onTap: onHome,
              ),
            ),
            Expanded(
              child: _BottomNavigationItem(
                icon: Icons.calendar_month_outlined,
                label: 'Agenda',
                active: currentIndex == 1,
                onTap: onAgenda,
              ),
            ),
            Expanded(
              child: _BottomNavigationItem(
                icon: thirdIcon,
                label: thirdLabel,
                active: currentIndex == 2,
                onTap: onThird,
              ),
            ),
            Expanded(
              child: _BottomNavigationItem(
                icon: fourthIcon,
                label: fourthLabel,
                active: currentIndex == 3,
                onTap: onFourth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? DogGoTheme.teal : DogGoTheme.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.05 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.body(
                  size: 10,
                  color: color,
                  weight: active
                      ? FontWeight.w900
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}