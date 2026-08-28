import 'package:flutter/material.dart';

import '../../../services/paseos_service.dart';
import '../../../services/walk_experience_service.dart';
import '../../../theme/doggo_theme.dart';
import '../../walks/models/walk_detail.dart';

class PetWalkCenter extends StatefulWidget {
  final int petId;
  final ValueChanged<WalkDetail> onOpenWalk;
  final VoidCallback onRequestWalk;

  const PetWalkCenter({
    super.key,
    required this.petId,
    required this.onOpenWalk,
    required this.onRequestWalk,
  });

  @override
  State<PetWalkCenter> createState() => _PetWalkCenterState();
}

class _PetWalkCenterState extends State<PetWalkCenter> {
  bool _loading = true;
  WalkDetail? _next;
  WalkDetail? _last;
  Map<String, dynamic>? _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await PaseosService.obtenerMisPaseos();
      Map<String, dynamic>? history;
      try {
        history = await WalkExperienceService.petHistory(widget.petId);
      } catch (_) {
        // El centro básico sigue disponible si el historial enriquecido
        // todavía no está habilitado en el servidor.
      }
      final source = response['data'];
      final rawList = source is List
          ? source
          : source is Map && source['elementos'] is List
          ? source['elementos'] as List
          : const [];
      final walks = rawList
          .whereType<Map>()
          .map((item) => WalkDetail.fromMap(Map<String, dynamic>.from(item)))
          .where((walk) => walk.pets.any((pet) => pet.id == widget.petId))
          .toList();
      final now = DateTime.now();
      final future =
          walks
              .where(
                (walk) =>
                    !walk.isFinished && walk.scheduledAt?.isAfter(now) == true,
              )
              .toList()
            ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
      final past = walks.where((walk) => walk.isFinished).toList()
        ..sort((a, b) {
          final left = a.finishedAt ?? a.cancelledAt ?? a.scheduledAt;
          final right = b.finishedAt ?? b.cancelledAt ?? b.scheduledAt;
          return (right ?? DateTime(0)).compareTo(left ?? DateTime(0));
        });
      if (!mounted) return;
      setState(() {
        _next = future.firstOrNull;
        _last = past.firstOrNull;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.dashboard_customize_rounded,
                color: DogGoTheme.teal,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Centro de paseos',
                  style: DogGoTheme.title(size: 17),
                ),
              ),
              if (!_loading)
                IconButton(
                  tooltip: 'Actualizar paseos',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator(minHeight: 4)
          else ...[
            if (_history != null) ...[
              _HistoryOverview(history: _history!),
              const SizedBox(height: 12),
            ],
            _WalkSummary(
              label: 'Próximo paseo',
              walk: _next,
              empty: 'No hay un paseo próximo.',
              onTap: _next == null ? null : () => widget.onOpenWalk(_next!),
            ),
            const SizedBox(height: 9),
            _WalkSummary(
              label: 'Último paseo',
              walk: _last,
              empty: 'Todavía no hay paseos anteriores.',
              onTap: _last == null ? null : () => widget.onOpenWalk(_last!),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onRequestWalk,
                icon: const Icon(Icons.directions_walk_rounded),
                label: const Text('Solicitar paseo para esta mascota'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryOverview extends StatelessWidget {
  final Map<String, dynamic> history;

  const _HistoryOverview({required this.history});

  @override
  Widget build(BuildContext context) {
    final walks = history['paseos'] is List
        ? (history['paseos'] as List).whereType<Map>().toList()
        : const <Map>[];
    final recent = walks.isEmpty ? null : walks.first;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de aventuras',
            style: DogGoTheme.body(
              size: 13,
              color: DogGoTheme.teal,
              weight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  value: '${history['paseosFinalizados'] ?? 0}',
                  label: 'completados',
                ),
              ),
              Expanded(
                child: _HistoryMetric(
                  value: '${_decimal(history['distanciaTotalKilometros'])} km',
                  label: 'recorridos',
                ),
              ),
              Expanded(
                child: _HistoryMetric(
                  value: '${history['minutosTotales'] ?? 0}',
                  label: 'minutos',
                ),
              ),
            ],
          ),
          if (recent != null) ...[
            const SizedBox(height: 11),
            Text(
              'Último reporte: ${recent['distanciaKilometros'] ?? 0} km · '
              '${recent['vecesAgua'] ?? 0} agua · '
              '${recent['incidentes'] ?? 0} incidentes',
              style: DogGoTheme.caption(size: 10, weight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  static String _decimal(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return (number ?? 0).toStringAsFixed(1);
  }
}

class _HistoryMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HistoryMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DogGoTheme.body(
          size: 13,
          color: DogGoTheme.teal,
          weight: FontWeight.w900,
        ),
      ),
      Text(label, style: DogGoTheme.caption(size: 9)),
    ],
  );
}

class _WalkSummary extends StatelessWidget {
  final String label;
  final WalkDetail? walk;
  final String empty;
  final VoidCallback? onTap;
  const _WalkSummary({
    required this.label,
    required this.walk,
    required this.empty,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: DogGoTheme.cream,
    borderRadius: BorderRadius.circular(16),
    child: ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(
        walk == null ? Icons.event_busy_rounded : Icons.event_available_rounded,
        color: walk == null ? DogGoTheme.muted : DogGoTheme.teal,
      ),
      title: Text(
        label,
        style: DogGoTheme.body(size: 12, weight: FontWeight.w800),
      ),
      subtitle: Text(
        walk == null
            ? empty
            : '${walk!.scheduledLabel} · ${walk!.status.label}',
        style: DogGoTheme.caption(size: 10.5),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
    ),
  );
}
