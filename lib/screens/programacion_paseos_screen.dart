import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_theme.dart';
import '../services/paseos_service.dart';
import '../services/perros_service.dart';
import 'home/models/home_walk.dart';
import 'home/models/home_walk_status.dart';
import 'home/widgets/home_walk_pet_avatar.dart';
import 'pets/models/pet.dart';

class ProgramacionPaseosScreen extends StatefulWidget {
  final int programacionId;
  final String? rol;

  const ProgramacionPaseosScreen({
    super.key,
    required this.programacionId,
    this.rol,
  });

  @override
  State<ProgramacionPaseosScreen> createState() =>
      _ProgramacionPaseosScreenState();
}

class _ProgramacionPaseosScreenState extends State<ProgramacionPaseosScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _status = '';
  List<HomeWalk> _walks = const [];
  List<Pet> _pets = const [];
  bool? _viewerIsOwner;

  bool get _isOwner => _viewerIsOwner ?? _normalize(widget.rol) != 'paseador';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PaseosService.obtenerProgramacion(widget.programacionId),
        if (_isOwner) PerrosService.obtenerMisPerros(),
      ]);
      final response = results.first;
      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'No se pudo cargar la programación.',
        );
      }
      final data = _map(response['data']);
      final rawWalks = data['paseos'];
      final walks = rawWalks is List
          ? rawWalks
                .whereType<Map>()
                .map(
                  (item) => HomeWalk.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <HomeWalk>[];
      final pets = _isOwner && results.length > 1
          ? Pet.listFrom(_map(results[1])['data'])
          : <Pet>[];
      if (!mounted) return;
      setState(() {
        _viewerIsOwner = data['esDuenio'] == true;
        _status = '${data['estado'] ?? ''}';
        _walks = walks;
        _pets = pets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      appBar: AppBar(
        title: const Text('Programación de paseos'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const DogGoLoadingView(message: 'Cargando programación...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                children: [
                  _SummaryCard(
                    count: _walks.length,
                    total: _walks.fold<double>(
                      0,
                      (sum, walk) => sum + (walk.price ?? 0),
                    ),
                    status: _status,
                    pending: _walks.where((walk) => walk.isPending).length,
                    accepted: _walks.where((walk) => walk.isAccepted).length,
                    completed: _walks.where((walk) => walk.isCompleted).length,
                    rejected: _walks
                        .where(
                          (walk) =>
                              walk.status == HomeWalkStatus.cancelled ||
                              walk.status == HomeWalkStatus.rejected,
                        )
                        .length,
                  ),
                  const SizedBox(height: 22),
                  Text('Paseos incluidos', style: DogGoTheme.title(size: 22)),
                  const SizedBox(height: 6),
                  Text(
                    _isOwner
                        ? 'Puedes ajustar o cancelar cada paseo mientras siga pendiente.'
                        : 'Revisa cada servicio incluido en esta programación.',
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                  const SizedBox(height: 14),
                  ..._walks.map(
                    (walk) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WalkCard(
                        walk: walk,
                        canManage: _isOwner && walk.isPending && !_saving,
                        canRespond: !_isOwner && walk.isPending && !_saving,
                        onEdit: () => _edit(walk),
                        onCancel: () => _cancelWalk(walk),
                        onAccept: () => _respond(walk, true),
                        onReject: () => _respond(walk, false),
                      ),
                    ),
                  ),
                  if (_isOwner && _walks.any((walk) => !walk.isCompleted)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DogGoTheme.red,
                      ),
                      onPressed: _saving ? null : _cancelAll,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar toda la programación'),
                    ),
                  ],
                  if (!_isOwner && _walks.any((walk) => walk.isPending)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _acceptAll,
                        icon: const Icon(Icons.done_all_rounded),
                        label: const Text('Aceptar todos los pendientes'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _edit(HomeWalk walk) async {
    var date = walk.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    var duration = walk.durationMinutes > 0 ? walk.durationMinutes : 30;
    var petIds = walk.effectivePets
        .map((pet) => pet.id)
        .whereType<int>()
        .toSet();
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DogGoTheme.cream,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) {
          final conflict = _findScheduleConflict(
            currentWalk: walk,
            start: date,
            durationMinutes: duration,
          );
          final isFuture = date.isAfter(
            DateTime.now().add(const Duration(minutes: 15)),
          );

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Editar paseo', style: DogGoTheme.title(size: 22)),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: const Icon(
                      Icons.event_rounded,
                      color: DogGoTheme.teal,
                    ),
                    title: Text(_dateLabel(date)),
                    subtitle: const Text('Fecha y hora'),
                    onTap: () async {
                      final day = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (day == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(date),
                      );
                      if (time == null) return;
                      update(() {
                        date = DateTime(
                          day.year,
                          day.month,
                          day.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Duración',
                    style: DogGoTheme.body(weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [30, 45, 60, 90]
                        .map(
                          (minutes) => ChoiceChip(
                            selected: duration == minutes,
                            label: Text(
                              minutes == 60
                                  ? '1 hora'
                                  : minutes == 90
                                  ? '1.5 horas'
                                  : '$minutes min',
                            ),
                            onSelected: (_) => update(() => duration = minutes),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mascotas',
                    style: DogGoTheme.body(weight: FontWeight.w800),
                  ),
                  ..._pets.map(
                    (pet) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: petIds.contains(pet.id),
                      title: Text(pet.name),
                      onChanged: (value) => update(() {
                        if (value == true && petIds.length < 5) {
                          petIds.add(pet.id);
                        } else if (value == false) {
                          petIds.remove(pet.id);
                        }
                      }),
                    ),
                  ),
                  if (!isFuture || conflict != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: DogGoTheme.redLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DogGoTheme.red.withValues(alpha: .25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.event_busy_rounded,
                            color: DogGoTheme.red,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              !isFuture
                                  ? 'El horario debe comenzar al menos 15 minutos después de la hora actual.'
                                  : 'Este horario se cruza con el paseo de ${conflict!.petName} (${conflict.formattedSchedule}, ${conflict.durationMinutes} min).',
                              style: DogGoTheme.body(
                                size: 12.5,
                                color: DogGoTheme.red,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: DogGoTheme.tealLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Horario disponible. El precio se recalculará automáticamente según la duración y las mascotas seleccionadas.',
                        style: DogGoTheme.body(
                          size: 12.5,
                          color: DogGoTheme.teal,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: petIds.isEmpty || !isFuture || conflict != null
                          ? null
                          : () => Navigator.pop(sheetContext, true),
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (accepted != true || !mounted) return;
    await _run(
      () => PaseosService.actualizarPaseoProgramado(
        programacionId: widget.programacionId,
        paseoId: walk.id!,
        fechaProgramada: date,
        duracionMinutos: duration,
        perroIds: petIds.toList(),
      ),
    );
  }

  HomeWalk? _findScheduleConflict({
    required HomeWalk currentWalk,
    required DateTime start,
    required int durationMinutes,
  }) {
    final end = start.add(Duration(minutes: durationMinutes));

    for (final candidate in _walks) {
      if (candidate.id == currentWalk.id ||
          candidate.scheduledAt == null ||
          candidate.status == HomeWalkStatus.cancelled ||
          candidate.status == HomeWalkStatus.rejected ||
          candidate.status == HomeWalkStatus.completed) {
        continue;
      }

      final candidateStart = candidate.scheduledAt!;
      final candidateEnd = candidateStart.add(
        Duration(minutes: candidate.durationMinutes),
      );
      if (start.isBefore(candidateEnd) && end.isAfter(candidateStart)) {
        return candidate;
      }
    }

    return null;
  }

  Future<void> _cancelWalk(HomeWalk walk) async {
    final ok = await _confirm(
      'Cancelar este paseo',
      'Los demás paseos del grupo permanecerán activos.',
    );
    if (ok != true) return;
    await _run(
      () => PaseosService.cancelarPaseo(
        walk.id!,
        motivo: 'Eliminado de la programación por el dueño',
      ),
    );
  }

  Future<void> _cancelAll() async {
    final ok = await _confirm(
      'Cancelar toda la programación',
      'Se cancelarán todos los paseos que todavía no hayan comenzado.',
    );
    if (ok != true) return;
    await _run(
      () => PaseosService.cancelarProgramacion(
        widget.programacionId,
        motivo: 'Cancelada por el dueño',
      ),
    );
  }

  Future<void> _respond(HomeWalk walk, bool accept) async {
    String? rejectionReason;
    if (!accept) {
      rejectionReason = await _requestRejectionReason(walk);
      if (rejectionReason == null) return;
    }
    await _run(
      () => PaseosService.responderPaseoProgramado(
        programacionId: widget.programacionId,
        paseoId: walk.id!,
        aceptar: accept,
        motivo: rejectionReason,
      ),
    );
  }

  Future<String?> _requestRejectionReason(HomeWalk walk) async {
    final controller = TextEditingController();
    const reasons = [
      'Horario no disponible',
      'Fuera de mi zona',
      'No puedo atender esas mascotas',
      'Imprevisto personal',
    ];
    String? selected;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final reason = controller.text.trim();
          return AlertDialog(
            title: const Text('Motivo del rechazo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${walk.petName} · ${walk.formattedSchedule}',
                    style: DogGoTheme.body(weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'El dueño recibirá este motivo y los demás paseos permanecerán sin cambios.',
                    style: DogGoTheme.subtitle(size: 12.5),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: reasons
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: selected == item,
                            onSelected: (_) => update(() {
                              selected = item;
                              controller.text = item;
                            }),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLength: 300,
                    maxLines: 3,
                    onChanged: (_) => update(() => selected = null),
                    decoration: const InputDecoration(
                      labelText: 'Explica brevemente el motivo',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Volver'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: DogGoTheme.red),
                onPressed: reason.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, reason),
                child: const Text('Rechazar paseo'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _acceptAll() async {
    final ok = await _confirm(
      'Aceptar todos los paseos',
      'Se aceptarán todos los servicios que todavía estén pendientes.',
      destructive: false,
    );
    if (ok != true) return;
    await _run(() => PaseosService.aceptarProgramacion(widget.programacionId));
  }

  Future<bool?> _confirm(
    String title,
    String message, {
    bool destructive = true,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? DogGoTheme.red : DogGoTheme.teal,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );

  Future<void> _run(Future<Map<String, dynamic>> Function() action) async {
    setState(() => _saving = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${result['message'] ?? ''}')));
    if (result['success'] == true) await _load();
  }

  static String _dateLabel(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static String _normalize(String? value) => (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('ñ', 'n')
      .replaceAll(' ', '');
}

class _SummaryCard extends StatelessWidget {
  final int count;
  final double total;
  final String status;
  final int pending;
  final int accepted;
  final int completed;
  final int rejected;
  const _SummaryCard({
    required this.count,
    required this.total,
    required this.status,
    required this.pending,
    required this.accepted,
    required this.completed,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLAN DE PASEOS',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          '$count paseos programados',
          style: DogGoTheme.title(size: 24, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              status.isEmpty ? 'Activa' : status,
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (pending > 0)
              _SummaryStatus(
                label: '$pending pendientes',
                icon: Icons.schedule,
              ),
            if (accepted > 0)
              _SummaryStatus(
                label: '$accepted aceptados',
                icon: Icons.check_circle_outline,
              ),
            if (completed > 0)
              _SummaryStatus(
                label: '$completed finalizados',
                icon: Icons.flag_outlined,
              ),
            if (rejected > 0)
              _SummaryStatus(
                label: '$rejected rechazados',
                icon: Icons.cancel_outlined,
              ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryStatus extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SummaryStatus({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _WalkCard extends StatelessWidget {
  final HomeWalk walk;
  final bool canManage;
  final bool canRespond;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const _WalkCard({
    required this.walk,
    required this.canManage,
    required this.canRespond,
    required this.onEdit,
    required this.onCancel,
    required this.onAccept,
    required this.onReject,
  });

  String get _reason =>
      '${walk.rawData['motivoCancelacion'] ?? ''}'
          .trim();

  Color get _statusColor {
    switch (walk.status) {
      case HomeWalkStatus.pending:
        return DogGoTheme.orange;
      case HomeWalkStatus.accepted:
        return DogGoTheme.green;
      case HomeWalkStatus.completed:
        return DogGoTheme.teal;
      case HomeWalkStatus.cancelled:
      case HomeWalkStatus.rejected:
        return DogGoTheme.red;
      default:
        return DogGoTheme.purple;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DogGoTheme.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            HomeWalkPetAvatar(
              imageUrls: walk.petImageUrls,
              fallbackImageUrl: walk.imageUrl,
              petCount: walk.petCount,
              size: 58,
              accentColor: _statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    walk.petName,
                    style: DogGoTheme.body(weight: FontWeight.w900),
                  ),
                  Text(
                    walk.formattedSchedule,
                    style: DogGoTheme.subtitle(size: 12),
                  ),
                  Text(
                    '${walk.durationMinutes} min · \$${(walk.price ?? 0).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                walk.status.label,
                style: DogGoTheme.body(
                  size: 11.5,
                  color: _statusColor,
                  weight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        if (_reason.isNotEmpty) ...[
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DogGoTheme.redLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Motivo: $_reason',
              style: DogGoTheme.body(
                size: 12,
                color: DogGoTheme.red,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
        if (canManage) ...[
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Quitar'),
                ),
              ),
            ],
          ),
        ],
        if (canRespond) ...[
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
