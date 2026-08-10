import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/home_summary.dart';

class HomeSummarySection extends StatelessWidget {
  final bool loading;
  final HomeSummary summary;

  const HomeSummarySection({
    super.key,
    required this.loading,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Esta semana', style: DogGoTheme.title(size: 20)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Actividad',
                  style: DogGoTheme.label(size: 9, color: DogGoTheme.teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen de los paseos finalizados',
            style: DogGoTheme.subtitle(size: 11),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const _SummaryLoading()
                : _SummaryContent(summary: summary),
          ),
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final HomeSummary summary;

  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasActivity = !summary.isEmpty;

    return Container(
      key: const ValueKey('summary-content'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF087D68), Color(0xFF10A184)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasActivity
                  ? Icons.insights_rounded
                  : Icons.directions_walk_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    value: '${summary.walks}',
                    label: summary.walks == 1 ? 'Paseo' : 'Paseos',
                    color: DogGoTheme.teal,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    value: summary.formattedDuration,
                    label: 'Duración',
                    color: DogGoTheme.purple,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    value: summary.formattedDistance,
                    label: 'Distancia',
                    color: DogGoTheme.orange,
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

class _SummaryMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: DogGoTheme.title(size: 15, color: color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.subtitle(size: 8.5),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: DogGoTheme.border);
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('summary-loading'),
      height: 106,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E8E6),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}
