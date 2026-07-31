import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../models/home_walk.dart';
import '../models/home_walk_status.dart';

class HomeAgendaSection extends StatefulWidget {
  final bool loading;
  final String? errorMessage;
  final List<HomeWalk> walks;
  final ValueChanged<HomeWalk> onWalkTap;
  final VoidCallback onSeeAll;
  final VoidCallback onRetry;

  const HomeAgendaSection({
    super.key,
    required this.loading,
    required this.walks,
    required this.onWalkTap,
    required this.onSeeAll,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  State<HomeAgendaSection> createState() =>
      _HomeAgendaSectionState();
}

class _HomeAgendaSectionState
    extends State<HomeAgendaSection> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final selectedWalks = _walksForDay(_selectedDate);
    final weeklyWalks = _walksForWeek(_selectedDate);
    final nextWalk = _findNextWalk();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DogGoSpacing.screenHorizontal,
        DogGoSpacing.screenTop,
        DogGoSpacing.screenHorizontal,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AgendaHeader(
            onSeeAll: widget.onSeeAll,
          ),
          const SizedBox(height: 24),
          _MonthSelector(
            selectedDate: _selectedDate,
            onPrevious: () => _changeWeek(-7),
            onNext: () => _changeWeek(7),
            onToday: _goToToday,
          ),
          const SizedBox(height: 14),
          _AgendaWeekStrip(
            selectedDate: _selectedDate,
            walks: widget.walks,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = _dateOnly(date);
              });
            },
          ),
          const SizedBox(height: 26),
          _buildContent(
            selectedWalks: selectedWalks,
            weeklyWalks: weeklyWalks,
            nextWalk: nextWalk,
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required List<HomeWalk> selectedWalks,
    required List<HomeWalk> weeklyWalks,
    required HomeWalk? nextWalk,
  }) {
    if (widget.loading) {
      return const Column(
        children: [
          DogGoSkeletonCard(height: 190),
          SizedBox(height: 24),
          DogGoSkeletonCard(height: 110),
          SizedBox(height: 12),
          DogGoSkeletonCard(height: 110),
          SizedBox(height: 24),
          DogGoSkeletonCard(height: 125),
        ],
      );
    }

    if (widget.errorMessage != null) {
      return DogGoErrorView(
        title: 'No pudimos cargar tu agenda',
        message: widget.errorMessage!,
        icon: Icons.event_busy_outlined,
        onRetry: widget.onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nextWalk != null) ...[
          _NextWalkCard(
            walk: nextWalk,
            onTap: () => widget.onWalkTap(nextWalk),
          ),
          const SizedBox(height: 30),
        ] else ...[
          _AgendaAvailableCard(
            onSeeAll: widget.onSeeAll,
          ),
          const SizedBox(height: 30),
        ],
        _DaySectionHeader(
          selectedDate: _selectedDate,
          walkCount: selectedWalks.length,
        ),
        const SizedBox(height: 14),
        if (selectedWalks.isEmpty)
          _FreeDayCard(
            selectedDate: _selectedDate,
          )
        else
          _DayTimeline(
            walks: selectedWalks,
            onWalkTap: widget.onWalkTap,
          ),
        const SizedBox(height: 30),
        _WeeklySummary(walks: weeklyWalks),
      ],
    );
  }

  void _changeWeek(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(
        Duration(days: days),
      );
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = _dateOnly(DateTime.now());
    });
  }

  List<HomeWalk> _walksForDay(DateTime date) {
    final result = widget.walks.where((walk) {
      final scheduled = walk.scheduledAt;

      return scheduled != null &&
          _sameDay(scheduled, date);
    }).toList();

    result.sort(_compareWalks);
    return result;
  }

  List<HomeWalk> _walksForWeek(DateTime date) {
    final start = _startOfWeek(date);
    final end = start.add(const Duration(days: 7));

    return widget.walks.where((walk) {
      final scheduled = walk.scheduledAt;

      if (scheduled == null) {
        return false;
      }

      return !scheduled.isBefore(start) &&
          scheduled.isBefore(end);
    }).toList();
  }

  HomeWalk? _findNextWalk() {
    final now = DateTime.now();

    final candidates = widget.walks.where((walk) {
      if (walk.isInProgress) {
        return true;
      }

      final scheduled = walk.scheduledAt;

      return walk.isUpcoming &&
          scheduled != null &&
          !scheduled.isBefore(now);
    }).toList();

    candidates.sort((first, second) {
      if (first.isInProgress && !second.isInProgress) {
        return -1;
      }

      if (!first.isInProgress && second.isInProgress) {
        return 1;
      }

      return _compareWalks(first, second);
    });

    return candidates.isEmpty ? null : candidates.first;
  }
}

class _AgendaHeader extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _AgendaHeader({
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agenda',
                style: DogGoTheme.title(size: 29),
              ),
              const SizedBox(height: 6),
              Text(
                'Organiza y consulta los paseos de tus mascotas',
                style: DogGoTheme.subtitle(size: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Ver todos'),
        ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _MonthSelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _monthAndYear(selectedDate),
            style: DogGoTheme.title(size: 18),
          ),
        ),
        TextButton(
          onPressed: onToday,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 38),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
            ),
            backgroundColor: DogGoTheme.tealLight,
            foregroundColor: DogGoTheme.teal,
          ),
          child: const Text('Hoy'),
        ),
        const SizedBox(width: 6),
        _CalendarArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Semana anterior',
          onPressed: onPrevious,
        ),
        const SizedBox(width: 4),
        _CalendarArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Semana siguiente',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CalendarArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      color: DogGoTheme.ink,
      iconSize: 21,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(38, 38),
        maximumSize: const Size(38, 38),
        backgroundColor: DogGoTheme.card,
        side: const BorderSide(
          color: DogGoTheme.border,
        ),
      ),
    );
  }
}

class _AgendaWeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final List<HomeWalk> walks;
  final ValueChanged<DateTime> onDateSelected;

  const _AgendaWeekStrip({
    required this.selectedDate,
    required this.walks,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final weekStart = _startOfWeek(selectedDate);

    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(
          Duration(days: index),
        );

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == 6 ? 0 : 5,
            ),
            child: _AgendaDay(
              date: date,
              selected: _sameDay(date, selectedDate),
              isToday: _sameDay(
                date,
                DateTime.now(),
              ),
              hasWalk: _hasWalkOnDate(
                walks,
                date,
              ),
              onTap: () => onDateSelected(date),
            ),
          ),
        );
      }),
    );
  }
}

class _AgendaDay extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool hasWalk;
  final VoidCallback onTap;

  const _AgendaDay({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.hasWalk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = [
      'L',
      'M',
      'M',
      'J',
      'V',
      'S',
      'D',
    ];

    final foreground = selected
        ? Colors.white
        : DogGoTheme.ink;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${weekdayLabels[date.weekday - 1]} ${date.day}',
      child: Material(
        color: selected
            ? DogGoTheme.teal
            : DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            DogGoRadius.medium,
          ),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
              border: Border.all(
                color: selected
                    ? DogGoTheme.teal
                    : isToday
                        ? DogGoTheme.teal
                        : DogGoTheme.border,
                width: isToday && !selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayLabels[date.weekday - 1],
                  style: DogGoTheme.body(
                    size: 10,
                    color: selected
                        ? Colors.white.withValues(
                            alpha: .75,
                          )
                        : DogGoTheme.muted,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${date.day}',
                  style: DogGoTheme.title(
                    size: 17,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasWalk
                        ? selected
                            ? DogGoTheme.orange
                            : DogGoTheme.teal
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextWalkCard extends StatelessWidget {
  final HomeWalk walk;
  final VoidCallback onTap;

  const _NextWalkCard({
    required this.walk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(walk.status);

    return Container(
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      walk.isInProgress
                          ? 'PASEO EN CURSO'
                          : 'PRÓXIMO PASEO',
                      style: DogGoTheme.label(
                        size: 10.5,
                        color: DogGoTheme.orangeLight,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: .14,
                        ),
                        borderRadius: BorderRadius.circular(
                          DogGoRadius.pill,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: .18,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            walk.status.label,
                            style: DogGoTheme.body(
                              size: 9.5,
                              color: Colors.white,
                              weight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WalkImage(
                      imageUrl: walk.imageUrl,
                      size: 78,
                      backgroundColor:
                          Colors.white.withValues(alpha: .14),
                      iconColor: Colors.white,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            walk.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.title(
                              size: 21,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _NextWalkDetail(
                            icon: Icons.schedule_rounded,
                            text: walk.formattedSchedule,
                          ),
                          const SizedBox(height: 4),
                          _NextWalkDetail(
                            icon: Icons.person_outline_rounded,
                            text: 'Con ${walk.walkerName}',
                          ),
                          if (walk.pickupAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _NextWalkDetail(
                              icon: Icons.location_on_outlined,
                              text: walk.pickupAddress,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: .15),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Toca para consultar los detalles',
                      style: DogGoTheme.caption(
                        size: 10.5,
                        color: Colors.white.withValues(
                          alpha: .76,
                        ),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextWalkDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _NextWalkDetail({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withValues(alpha: .75),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 11.5,
              color: Colors.white.withValues(alpha: .88),
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgendaAvailableCard extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _AgendaAvailableCard({
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DogGoTheme.tealLight,
            DogGoTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.teal.withValues(alpha: .12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: DogGoTheme.card,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: DogGoTheme.teal,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu agenda está disponible',
                  style: DogGoTheme.title(size: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuando agendes un paseo aparecerá destacado aquí.',
                  style: DogGoTheme.subtitle(size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSeeAll,
            tooltip: 'Ver mis paseos',
            icon: const Icon(
              Icons.arrow_forward_rounded,
            ),
            color: DogGoTheme.teal,
            style: IconButton.styleFrom(
              backgroundColor: DogGoTheme.card,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySectionHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int walkCount;

  const _DaySectionHeader({
    required this.selectedDate,
    required this.walkCount,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(
      selectedDate,
      DateTime.now(),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isToday ? 'Tu día' : _dayTitle(selectedDate),
                style: DogGoTheme.title(size: 21),
              ),
              const SizedBox(height: 4),
              Text(
                walkCount == 0
                    ? 'No tienes servicios programados'
                    : walkCount == 1
                        ? 'Tienes un paseo programado'
                        : 'Tienes $walkCount paseos programados',
                style: DogGoTheme.subtitle(size: 12),
              ),
            ],
          ),
        ),
        if (walkCount > 0)
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$walkCount',
              style: DogGoTheme.body(
                size: 12,
                color: DogGoTheme.teal,
                weight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayTimeline extends StatelessWidget {
  final List<HomeWalk> walks;
  final ValueChanged<HomeWalk> onWalkTap;

  const _DayTimeline({
    required this.walks,
    required this.onWalkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(walks.length, (index) {
        final walk = walks[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == walks.length - 1 ? 0 : 12,
          ),
          child: _TimelineWalkCard(
            walk: walk,
            isLast: index == walks.length - 1,
            onTap: () => onWalkTap(walk),
          ),
        );
      }),
    );
  }
}

class _TimelineWalkCard extends StatelessWidget {
  final HomeWalk walk;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineWalkCard({
    required this.walk,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(walk.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Column(
            children: [
              Text(
                _timeLabel(walk.scheduledAt),
                style: DogGoTheme.body(
                  size: 10.5,
                  color: DogGoTheme.ink,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DogGoTheme.card,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: .2),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 78,
                  margin: const EdgeInsets.only(top: 5),
                  color: DogGoTheme.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Material(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                DogGoRadius.large,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.large,
                  ),
                  border: Border.all(
                    color: DogGoTheme.border,
                  ),
                  boxShadow: DogGoTheme.softShadow(
                    opacity: .025,
                    blur: 16,
                    offset: const Offset(0, 6),
                  ),
                ),
                child: Row(
                  children: [
                    _WalkImage(
                      imageUrl: walk.imageUrl,
                      size: 54,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            walk.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.title(size: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Con ${walk.walkerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(
                              size: 11.5,
                            ),
                          ),
                          if (walk.pickupAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: DogGoTheme.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    walk.pickupAddress,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: DogGoTheme.caption(
                                      size: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: .11,
                            ),
                            borderRadius: BorderRadius.circular(
                              DogGoRadius.pill,
                            ),
                          ),
                          child: Text(
                            walk.status.label,
                            style: DogGoTheme.body(
                              size: 8.5,
                              color: statusColor,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: DogGoTheme.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FreeDayCard extends StatelessWidget {
  final DateTime selectedDate;

  const _FreeDayCard({
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(
      selectedDate,
      DateTime.now(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: DogGoTheme.orangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: DogGoTheme.orange,
              size: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isToday
                ? 'Un día tranquilo'
                : 'Este día está libre',
            style: DogGoTheme.title(size: 17),
          ),
          const SizedBox(height: 5),
          Text(
            isToday
                ? 'No tienes paseos programados para hoy.'
                : 'No hay paseos programados para esta fecha.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  final List<HomeWalk> walks;

  const _WeeklySummary({
    required this.walks,
  });

  @override
  Widget build(BuildContext context) {
    final completedWalks = walks.where((walk) {
      return walk.status == HomeWalkStatus.completed;
    }).toList();

    final summarySource = completedWalks.isEmpty
        ? walks
        : completedWalks;

    final totalMinutes = summarySource.fold<int>(
      0,
      (total, walk) => total + walk.durationMinutes,
    );

    final totalDistance = summarySource.fold<double>(
      0,
      (total, walk) =>
          total + walk.distanceKilometers,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esta semana',
          style: DogGoTheme.title(size: 21),
        ),
        const SizedBox(height: 4),
        Text(
          completedWalks.isEmpty
              ? 'Resumen de tus servicios programados'
              : 'Actividad de tus paseos finalizados',
          style: DogGoTheme.subtitle(size: 12),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            border: Border.all(
              color: DogGoTheme.border,
            ),
            boxShadow: DogGoTheme.softShadow(
              opacity: .025,
              blur: 18,
              offset: const Offset(0, 7),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.pets_outlined,
                  value: '${summarySource.length}',
                  label: 'Paseos',
                  color: DogGoTheme.teal,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.schedule_outlined,
                  value: _durationLabel(totalMinutes),
                  label: 'Duración',
                  color: DogGoTheme.purple,
                ),
              ),
              const _SummaryDivider(),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.straighten_rounded,
                  value: _distanceLabel(totalDistance),
                  label: 'Distancia',
                  color: DogGoTheme.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
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
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.title(size: 16),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: DogGoTheme.caption(
            size: 10.5,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 58,
      color: DogGoTheme.divider,
    );
  }
}

class _WalkImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const _WalkImage({
    required this.imageUrl,
    required this.size,
    this.backgroundColor = DogGoTheme.tealLight,
    this.iconColor = DogGoTheme.teal,
  });

  bool get _hasImage {
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          DogGoRadius.medium,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasImage
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return _WalkImagePlaceholder(
                  iconColor: iconColor,
                );
              },
            )
          : _WalkImagePlaceholder(
              iconColor: iconColor,
            ),
    );
  }
}

class _WalkImagePlaceholder extends StatelessWidget {
  final Color iconColor;

  const _WalkImagePlaceholder({
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.pets_rounded,
      color: iconColor,
      size: 27,
    );
  }
}

bool _hasWalkOnDate(
  List<HomeWalk> walks,
  DateTime date,
) {
  return walks.any((walk) {
    final scheduled = walk.scheduledAt;

    return scheduled != null &&
        _sameDay(scheduled, date);
  });
}

bool _sameDay(
  DateTime first,
  DateTime second,
) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(
    date.year,
    date.month,
    date.day,
  );
}

DateTime _startOfWeek(DateTime date) {
  final day = _dateOnly(date);

  return day.subtract(
    Duration(days: day.weekday - 1),
  );
}

int _compareWalks(
  HomeWalk first,
  HomeWalk second,
) {
  final firstDate = first.scheduledAt;
  final secondDate = second.scheduledAt;

  if (firstDate == null && secondDate == null) {
    return 0;
  }

  if (firstDate == null) {
    return 1;
  }

  if (secondDate == null) {
    return -1;
  }

  return firstDate.compareTo(secondDate);
}

String _monthAndYear(DateTime date) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

String _dayTitle(DateTime date) {
  const weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  return '${weekdays[date.weekday - 1]} ${date.day}';
}

String _timeLabel(DateTime? date) {
  if (date == null) {
    return '--:--';
  }

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _durationLabel(int minutes) {
  if (minutes <= 0) {
    return '0 min';
  }

  if (minutes < 60) {
    return '$minutes min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (remainingMinutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remainingMinutes}m';
}

String _distanceLabel(double distance) {
  if (distance <= 0) {
    return '0 km';
  }

  final decimals = distance == distance.roundToDouble()
      ? 0
      : 1;

  return '${distance.toStringAsFixed(decimals)} km';
}

Color _statusColor(HomeWalkStatus status) {
  switch (status) {
    case HomeWalkStatus.pending:
      return DogGoTheme.orange;

    case HomeWalkStatus.accepted:
      return const Color(0xFF9BE4D2);

    case HomeWalkStatus.inProgress:
      return const Color(0xFF78D8C2);

    case HomeWalkStatus.completed:
      return DogGoTheme.green;

    case HomeWalkStatus.cancelled:
    case HomeWalkStatus.rejected:
      return DogGoTheme.red;

    case HomeWalkStatus.none:
    case HomeWalkStatus.unknown:
      return DogGoTheme.muted;
  }
}