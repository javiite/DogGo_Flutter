import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../models/home_summary.dart';

class HomeSummarySection
    extends StatelessWidget {
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
      padding: const EdgeInsets.fromLTRB(
        24,
        28,
        24,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Tu semana',
            style: DogGoTheme.title(
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Actividad de los paseos finalizados',
            style: DogGoTheme.subtitle(
              size: 12,
            ),
          ),
          const SizedBox(height: 13),
          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 250,
            ),
            child: loading
                ? const _SummaryLoading()
                : _SummaryContent(
                    summary: summary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryContent
    extends StatelessWidget {
  final HomeSummary summary;

  const _SummaryContent({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity =
        summary.walks > 0;

    return Container(
      key: const ValueKey(
        'summary-content',
      ),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF0FAF7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  color:
                      DogGoTheme.tealLight,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Icon(
                  hasActivity
                      ? Icons
                          .insights_rounded
                      : Icons
                          .directions_walk_rounded,
                  color: DogGoTheme.teal,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActivity
                          ? _activityTitle()
                          : 'Una semana por comenzar',
                      style:
                          DogGoTheme.title(
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasActivity
                          ? 'Cada paseo suma bienestar y nuevas aventuras.'
                          : 'Los paseos finalizados aparecerán en este resumen.',
                      style:
                          DogGoTheme.subtitle(
                        size: 10.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding:
                const EdgeInsets.symmetric(
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.75,
              ),
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: DogGoTheme.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    icon:
                        Icons.route_rounded,
                    value:
                        '${summary.walks}',
                    label: summary.walks == 1
                        ? 'Paseo'
                        : 'Paseos',
                    color:
                        DogGoTheme.teal,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons
                        .schedule_rounded,
                    value: summary
                        .formattedDuration,
                    label: 'Duración',
                    color:
                        DogGoTheme.purple,
                  ),
                ),
                const _MetricDivider(),
                Expanded(
                  child: _SummaryMetric(
                    icon: Icons
                        .straighten_rounded,
                    value: summary
                        .formattedDistance,
                    label: 'Distancia',
                    color:
                        DogGoTheme.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _activityTitle() {
    if (summary.walks == 1) {
      return 'Completaste un paseo';
    }

    return 'Completaste ${summary.walks} paseos';
  }
}

class _SummaryMetric
    extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: DogGoTheme.title(
              size: 17,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: DogGoTheme.subtitle(
            size: 9.5,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider
    extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: DogGoTheme.border,
    );
  }
}

class _SummaryLoading
    extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey(
        'summary-loading',
      ),
      height: 175,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: const Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }
}