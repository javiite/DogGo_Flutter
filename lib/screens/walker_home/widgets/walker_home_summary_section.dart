import 'package:flutter/material.dart';

import '../models/walker_home_profile.dart';

class WalkerHomeSummarySection extends StatelessWidget {
  final WalkerHomeProfile? profile;
  final bool savingAvailability;
  final int activeCount;
  final int scheduledCount;
  final int pendingCount;
  final int completedCount;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onProfileTap;
  final VoidCallback onWalksTap;

  const WalkerHomeSummarySection({
    super.key,
    required this.profile,
    required this.savingAvailability,
    required this.activeCount,
    required this.scheduledCount,
    required this.pendingCount,
    required this.completedCount,
    required this.onAvailabilityChanged,
    required this.onProfileTap,
    required this.onWalksTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = profile;
    final available = current?.available ?? false;
    final completion = current?.completionPercentage ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: available
                ? const Color(0xFFE7F4F1)
                : const Color(0xFFF0F1F2),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: available
                  ? const Color(0xFFC3E0D8)
                  : const Color(0xFFDCDDDF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  available
                      ? Icons.online_prediction_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: available
                      ? const Color(0xFF087D68)
                      : const Color(0xFF70737A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      available ? 'Disponible' : 'No disponible',
                      style: const TextStyle(
                        color: Color(0xFF20212B),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      available
                          ? 'Puedes recibir nuevas solicitudes.'
                          : 'No aparecerás para nuevas solicitudes.',
                      style: const TextStyle(
                        color: Color(0xFF73767D),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (savingAvailability)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Switch.adaptive(
                  value: available,
                  onChanged: current == null
                      ? null
                      : onAvailabilityChanged,
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.25,
          children: [
            _MetricTile(
              value: activeCount,
              label: 'Activos',
              icon: Icons.directions_walk_rounded,
              color: const Color(0xFF087D68),
            ),
            _MetricTile(
              value: scheduledCount,
              label: 'En agenda',
              icon: Icons.event_available_rounded,
              color: const Color(0xFF7554B8),
            ),
            _MetricTile(
              value: pendingCount,
              label: 'Pendientes',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFD87812),
            ),
            _MetricTile(
              value: completedCount,
              label: 'Terminados',
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF3B8656),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFE0E2E1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFF7554B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Perfil profesional',
                          style: TextStyle(
                            color: Color(0xFF20212B),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          completion >= 100
                              ? 'Tu información está completa.'
                              : 'Completado al $completion %',
                          style: const TextStyle(
                            color: Color(0xFF73767D),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onProfileTap,
                    child: const Text('Editar'),
                  ),
                ],
              ),
              if (completion < 100) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: completion / 100,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE8E5EF),
                    color: const Color(0xFF7554B8),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onWalksTap,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Ver todos mis paseos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE0E2E1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Color(0xFF20212B),
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF74767E),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
