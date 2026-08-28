import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/walker_availability.dart';

class AvailabilityBlocksSection extends StatelessWidget {
  final List<WalkerCalendarBlock> blocks;
  final List<WalkerCalendarBlock> occupations;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  const AvailabilityBlocksSection({
    super.key,
    required this.blocks,
    required this.occupations,
    required this.busy,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingBlocks =
        blocks.where((item) => item.localEnd.isAfter(DateTime.now())).toList()
          ..sort((a, b) => a.localStart.compareTo(b.localStart));
    final upcomingWalks =
        occupations
            .where((item) => item.localEnd.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.localStart.compareTo(b.localStart));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ausencias y agenda',
                style: TextStyle(
                  color: DogGoTheme.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Bloquear'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Los paseos aceptados se reservan automáticamente.',
          style: TextStyle(color: DogGoTheme.muted, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        if (upcomingBlocks.isEmpty && upcomingWalks.isEmpty)
          _EmptyAgenda(onAdd: onAdd)
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Column(
              children: [
                ...upcomingWalks
                    .take(4)
                    .map(
                      (item) => _AgendaTile(
                        item: item,
                        icon: Icons.pets_rounded,
                        label: 'Paseo reservado',
                        color: DogGoTheme.teal,
                      ),
                    ),
                ...upcomingBlocks.map(
                  (item) => _AgendaTile(
                    item: item,
                    icon: Icons.event_busy_rounded,
                    label: item.reason?.trim().isNotEmpty == true
                        ? item.reason!.trim()
                        : 'Tiempo no disponible',
                    color: DogGoTheme.orange,
                    onDelete: busy ? null : () => onDelete(item.id),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final WalkerCalendarBlock item;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onDelete;

  const _AgendaTile({
    required this.item,
    required this.icon,
    required this.label,
    required this.color,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(_range(item.localStart, item.localEnd)),
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: 'Eliminar bloqueo',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
    );
  }

  static String _range(DateTime start, DateTime end) {
    String two(int value) => value.toString().padLeft(2, '0');
    final date = '${two(start.day)}/${two(start.month)}';
    return '$date · ${two(start.hour)}:${two(start.minute)} a '
        '${two(end.day)}/${two(end.month)} · ${two(end.hour)}:${two(end.minute)}';
  }
}

class _EmptyAgenda extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyAgenda({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: DogGoTheme.teal,
            size: 34,
          ),
          const SizedBox(height: 9),
          const Text(
            'Tu agenda está libre',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega una ausencia cuando no puedas recibir paseos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DogGoTheme.muted, fontSize: 12.5),
          ),
          TextButton(onPressed: onAdd, child: const Text('Agregar ausencia')),
        ],
      ),
    );
  }
}
