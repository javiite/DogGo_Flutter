import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/home_summary.dart';
import '../widgets/home_section_title.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSectionTitle(
            title: 'Esta semana',
            subtitle: 'Actividad de tus paseos finalizados',
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
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

  const _SummaryContent({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('summary-content'),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.route_outlined,
              value: '${summary.walks}',
              label: summary.walks == 1 ? 'Paseo' : 'Paseos',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.schedule_outlined,
              value: summary.formattedDuration,
              label: 'Duración',
            ),
          ),
          const _MetricDivider(),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.straighten_rounded,
              value: summary.formattedDistance,
              label: 'Distancia',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: DogGoTheme.teal,
          size: 21,
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: DogGoTheme.title(
              size: 18,
              color: DogGoTheme.ink,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: DogGoTheme.subtitle(size: 10.5),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      color: DogGoTheme.border,
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('summary-loading'),
      height: 112,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}