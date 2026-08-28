import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_theme.dart';
import '../services/app_preferences_service.dart';
import '../widgets/doggo_map_preview.dart';
import 'pets/models/pet.dart';
import 'registrar_perro_screen.dart';
import 'onboarding/contextual_onboarding.dart';
import 'seleccionar_ubicacion_screen.dart';
import 'walks/walk_request_controller.dart';
import 'walks/walk_request_state.dart';
import 'walks/models/walk_route_selection.dart';
import 'walks/models/walk_request_draft.dart';
import 'walks/widgets/walk_route_card.dart';
import 'walks/widgets/available_date_selector.dart';
import 'walks/widgets/available_time_selector.dart';
import 'walks/widgets/availability_warning_card.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;
  final int? initialPetId;
  final WalkRequestDraft? initialDraft;

  const CrearPaseoScreen({
    super.key,
    required this.paseador,
    this.initialPetId,
    this.initialDraft,
  });

  @override
  State<CrearPaseoScreen> createState() => _CrearPaseoScreenState();
}

class _CrearPaseoScreenState extends State<CrearPaseoScreen> {
  late final WalkRequestController _controller;

  final TextEditingController _notesController = TextEditingController();

  WalkRouteSelection? _routeSelection;
  Timer? _draftTimer;
  bool _draftReady = false;
  bool _draftRestored = false;
  bool _showAllScheduledWalks = false;

  @override
  void initState() {
    super.initState();

    _controller = WalkRequestController(
      walkerData: widget.paseador,
      initialPetId: widget.initialPetId,
    );

    _controller.addListener(_scheduleDraftSave);
    _notesController.addListener(_scheduleDraftSave);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    if (!mounted ||
        _controller.state.loading ||
        _controller.state.error != null) {
      return;
    }
    WalkRequestDraft? draft = widget.initialDraft;
    draft ??= await AppPreferencesService.loadJson(
      'walk_request_draft',
    ).then((value) => value == null ? null : WalkRequestDraft.fromMap(value));
    if (draft != null && draft.walkerId == _controller.state.walker.id) {
      _controller.applyDraft(draft);
      _notesController.text = draft.notes;
      _draftRestored = true;
    }
    _draftReady = true;
    if (mounted) setState(() {});
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showContextualOnboarding(
        context,
        contextKey: 'walk_request',
        title: 'Solicita con confianza',
        steps: const [
          OnboardingStep(
            Icons.pets_rounded,
            'Elige las mascotas',
            'Puedes solicitar el mismo horario para una o varias mascotas.',
          ),
          OnboardingStep(
            Icons.event_available_rounded,
            'Confirma agenda y lugar',
            'DogGo valida disponibilidad, duración y punto de recogida.',
          ),
          OnboardingStep(
            Icons.edit_note_rounded,
            'Tu avance se conserva',
            'Si sales antes de enviar, recuperaremos este borrador.',
          ),
        ],
      );
    });
  }

  void _scheduleDraftSave() {
    if (!_draftReady || _controller.state.loading || _controller.state.saving) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final state = _controller.state;
    await AppPreferencesService.saveJson(
      'walk_request_draft',
      WalkRequestDraft(
        walkerId: state.walker.id,
        petIds: state.selectedPetIds,
        durationMinutes: state.durationMinutes,
        scheduledAt: state.scheduledAt,
        pickupLocation: state.pickupLocation,
        notes: _notesController.text,
        updatedAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> _discardDraft() async {
    _draftTimer?.cancel();
    _draftReady = false;
    _controller.discardDraftState();
    _notesController.clear();
    _routeSelection = null;
    await AppPreferencesService.remove('walk_request_draft');
    if (!mounted) return;
    setState(() {
      _draftRestored = false;
      _showAllScheduledWalks = false;
    });
    _draftReady = true;
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _controller.removeListener(_scheduleDraftSave);
    _notesController.removeListener(_scheduleDraftSave);
    _notesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ignore: unused_element
  Future<void> _selectSchedule() async {
    final now = DateTime.now();
    final current = _controller.state.scheduledAt;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'Selecciona el día del paseo',
      cancelText: 'Cancelar',
      confirmText: 'Continuar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: DogGoTheme.teal),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final initialDateTime = current ?? now.add(const Duration(hours: 1));

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDateTime),
      helpText: 'Selecciona la hora',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: DogGoTheme.teal),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) {
      return;
    }

    final result = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (!result.isAfter(DateTime.now())) {
      _showMessage('Selecciona una fecha y hora futuras.');
      return;
    }

    _controller.setSchedule(result);
  }

  Future<void> _openMap() async {
    final current = _controller.state.pickupLocation;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: current == null
              ? null
              : LatLng(current.latitude, current.longitude),
          textoInicial: current?.displayAddress,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final error = _controller.applyMapResult(result);

    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _useCurrentLocation() async {
    final error = await _controller.useCurrentLocation();

    if (!mounted) {
      return;
    }

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage('Ubicación actual seleccionada.', success: true);
  }

  void _useDefaultLocation() {
    final error = _controller.useDefaultLocation();

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage('Domicilio predeterminado seleccionado.', success: true);
  }

  void _togglePet(int petId) {
    final error = _controller.togglePet(petId);

    if (error != null) {
      _showMessage(error);
    }
  }

  void _addSchedule() {
    final error = _controller.addCurrentSchedule();
    if (error != null) {
      _showMessage(error);
      return;
    }
    setState(() => _showAllScheduledWalks = false);
  }

  void _addWeekly(int weeks) {
    final before = _controller.state.scheduledWalks.length;
    final error = _controller.addWeeklySchedules(weeks);
    if (error != null) {
      _showMessage(error);
      return;
    }
    final added = _controller.state.scheduledWalks.length - before;
    setState(() => _showAllScheduledWalks = false);
    _showMessage('$added paseos semanales agregados.', success: true);
  }

  Future<void> _registerPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarPerroScreen()),
    );

    if (!mounted) {
      return;
    }

    await _controller.initialize();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final result = await _controller.submit(
      notes: _notesController.text,
      routeSelection: _routeSelection,
    );

    if (!mounted) {
      return;
    }

    _showMessage(result.message, success: result.success);

    if (result.success) {
      _draftTimer?.cancel();
      await AppPreferencesService.remove('walk_request_draft');
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return DogGoScreenScaffold(
          title: 'Solicitar paseo',
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          bottomNavigationBar: state.loading || state.error != null
              ? null
              : _SubmitBar(state: state, onSubmit: _submit),
          body: SafeArea(top: false, child: _buildBody(state)),
        );
      },
    );
  }

  Widget _buildBody(WalkRequestState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Preparando tu solicitud...');
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: DogGoErrorView(
          message: state.error!,
          onRetry: _controller.initialize,
        ),
      );
    }

    return RefreshIndicator(
      color: DogGoTheme.teal,
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
        children: [
          if (_draftRestored) ...[
            _DraftRestoredBanner(onDiscard: _discardDraft),
            const SizedBox(height: 14),
          ],
          _WalkerHero(state: state),
          const SizedBox(height: 26),

          _SectionHeader(
            title: '¿Quiénes salen?',
            subtitle: 'Selecciona de 1 a 5 mascotas',
            trailing:
                '${state.selectedPetCount}/'
                '${WalkRequestState.maxSelectedPets}',
          ),
          const SizedBox(height: 12),

          if (state.pets.isEmpty)
            _NoPetsCard(onRegister: _registerPet)
          else ...[
            _PetSelector(state: state, onSelected: _togglePet),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _registerPet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar otra mascota'),
            ),
          ],

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Duración',
            subtitle: 'Elige cuánto durará el paseo',
          ),
          const SizedBox(height: 12),

          _DurationSelector(
            state: state,
            onSelected: _controller.selectDuration,
          ),
          if (state.scheduledWalks.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ProgramDraftHint(existingWalkCount: state.scheduledWalks.length),
          ],

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Fecha y hora',
            subtitle: 'Programa el momento del paseo',
          ),
          const SizedBox(height: 12),

          AvailabilityWarningCard(
            loading: state.loadingAvailability,
            unavailable: state.availability?.available == false,
            error: state.availabilityError,
            onRetry: _controller.loadAvailability,
          ),
          if (state.availability != null && state.availability!.available) ...[
            const SizedBox(height: 12),
            AvailableDateSelector(
              dates: state.availability!.availableDays(
                DateTime.now(),
                count: 60,
              ),
              selected: state.selectedDay,
              onSelected: _controller.selectDay,
            ),
            const SizedBox(height: 10),
            AvailableTimeSelector(
              times: state.currentSlotOptions,
              selected: state.scheduledAt,
              onSelected: _controller.setSchedule,
            ),
            if (state.scheduledAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'Seleccionado: ${state.scheduleLabel}',
                style: DogGoTheme.caption(
                  color: DogGoTheme.teal,
                  weight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _addSchedule,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(
                  state.scheduledWalks.isEmpty
                      ? 'Agregar otra fecha'
                      : 'Agregar esta fecha a la programación',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _addWeekly(4),
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: const Text('1 mes · 4'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => _addWeekly(8),
                      icon: const Icon(Icons.calendar_view_month_rounded),
                      label: const Text('2 meses · 8'),
                    ),
                  ),
                ],
              ),
            ],
            if (state.scheduledWalks.isNotEmpty) ...[
              const SizedBox(height: 14),
              _ScheduleProgramCard(
                state: state,
                expanded: _showAllScheduledWalks,
                onToggle: () => setState(
                  () => _showAllScheduledWalks = !_showAllScheduledWalks,
                ),
                onRemove: (walk) {
                  _controller.removeSchedule(walk);
                  if (_controller.state.scheduledWalks.length <= 2) {
                    setState(() => _showAllScheduledWalks = false);
                  }
                },
              ),
            ],
          ],

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Punto de recogida',
            subtitle: '¿Dónde recogerán a tus mascotas?',
          ),
          const SizedBox(height: 12),

          _LocationCard(
            state: state,
            onDefault: _useDefaultLocation,
            onCurrent: _useCurrentLocation,
            onMap: _openMap,
          ),

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Recorrido',
            subtitle: 'Define por dónde será el paseo',
          ),
          const SizedBox(height: 12),

          WalkRouteCard(
            pickupLocation: state.pickupLocation,
            selection: _routeSelection,
            onChanged: (selection) {
              setState(() {
                _routeSelection = selection;
              });
            },
          ),

          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Indicaciones',
            subtitle: 'Información útil para el paseador',
          ),
          const SizedBox(height: 12),

          _NotesField(controller: _notesController),

          const SizedBox(height: 28),
          _PriceSummary(state: state),
        ],
      ),
    );
  }
}

class _DraftRestoredBanner extends StatelessWidget {
  final VoidCallback onDiscard;

  const _DraftRestoredBanner({required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DogGoTheme.orange.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: DogGoTheme.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recuperamos tu solicitud pendiente.',
              style: DogGoTheme.body(size: 12, weight: FontWeight.w800),
            ),
          ),
          TextButton(onPressed: onDiscard, child: const Text('Descartar')),
        ],
      ),
    );
  }
}

class _WalkerHero extends StatelessWidget {
  final WalkRequestState state;

  const _WalkerHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final walker = state.walker;
    final photoUrl = state.walkerPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: DogGoTheme.teal.withValues(alpha: .16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .20)),
            ),
            child: DogGoNetworkImage(
              url: photoUrl,
              semanticLabel: 'Fotografía de ${walker.name}',
              fallback: _Initials(text: walker.initials, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TU PASEADOR',
                  style: DogGoTheme.label(
                    size: 10,
                    color: Colors.white.withValues(alpha: .72),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  walker.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DogGoTheme.title(size: 21, color: Colors.white),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _HeroData(
                      icon: Icons.star_rounded,
                      text: walker.rating > 0
                          ? walker.rating.toStringAsFixed(1)
                          : 'Nuevo',
                    ),
                    _HeroData(
                      icon: Icons.location_on_outlined,
                      text: walker.serviceZone,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroData extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroData({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: DogGoTheme.orange, size: 16),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.caption(
              size: 10.5,
              color: Colors.white,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgramDraftHint extends StatelessWidget {
  final int existingWalkCount;

  const _ProgramDraftHint({required this.existingWalkCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.add_rounded, size: 19, color: DogGoTheme.teal),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Ahora estás preparando un paseo adicional. Los $existingWalkCount ya agregados conservarán sus mascotas y duración.',
              style: const TextStyle(
                color: DogGoTheme.tealDark,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
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
              Text(title, style: DogGoTheme.title(size: 22)),
              const SizedBox(height: 3),
              Text(subtitle, style: DogGoTheme.subtitle(size: 12)),
            ],
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: DogGoTheme.label(size: 11, color: DogGoTheme.teal),
            ),
          ),
      ],
    );
  }
}

class _PetSelector extends StatelessWidget {
  final WalkRequestState state;
  final ValueChanged<int> onSelected;

  const _PetSelector({required this.state, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: state.pets.map((pet) {
        final selected = state.isPetSelected(pet.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PetCard(
            pet: pet,
            photoUrl: state.petPhotoUrl(pet),
            selected: selected,
            onTap: () => onSelected(pet.id),
          ),
        );
      }).toList(),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _PetCard({
    required this.pet,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${pet.name}, ${selected ? "seleccionado" : "no seleccionado"}',
      child: Material(
        color: selected ? DogGoTheme.tealLight : DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? DogGoTheme.teal : DogGoTheme.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: DogGoTheme.card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: photoUrl != null && photoUrl!.trim().isNotEmpty
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return _Initials(
                              text: pet.initials,
                              color: DogGoTheme.teal,
                            );
                          },
                        )
                      : _Initials(text: pet.initials, color: DogGoTheme.teal),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.title(size: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.shortDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.subtitle(size: 11),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pet.size,
                        style: DogGoTheme.caption(
                          size: 10,
                          color: DogGoTheme.teal,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? DogGoTheme.teal : DogGoTheme.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? DogGoTheme.teal : DogGoTheme.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 19,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  final VoidCallback onRegister;

  const _NoPetsCard({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.pets_outlined, color: DogGoTheme.teal, size: 40),
          const SizedBox(height: 10),
          Text(
            'No tienes mascotas registradas',
            textAlign: TextAlign.center,
            style: DogGoTheme.title(size: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Registra una mascota antes de solicitar el paseo.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 12),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRegister,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Registrar mascota'),
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final WalkRequestState state;
  final ValueChanged<int> onSelected;

  const _DurationSelector({required this.state, required this.onSelected});

  Future<void> _selectCustomDuration(BuildContext context) async {
    var minutes = state.durationMinutes
        .clamp(
          WalkRequestState.minDurationMinutes,
          WalkRequestState.maxDurationMinutes,
        )
        .toDouble();

    final result = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: DogGoTheme.card,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedMinutes = minutes.round();
            final price = state.hourlyRate * (selectedMinutes / 60);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DogGoTheme.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Duración personalizada',
                    style: DogGoTheme.title(size: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Elige entre 30 y 90 minutos',
                    style: DogGoTheme.subtitle(size: 11.5),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: DogGoTheme.tealLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _durationLabel(selectedMinutes),
                          style: DogGoTheme.title(
                            size: 29,
                            color: DogGoTheme.teal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '\$${price.toStringAsFixed(2)} por paseo para una mascota',
                          style: DogGoTheme.caption(size: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Slider(
                    value: minutes,
                    min: WalkRequestState.minDurationMinutes.toDouble(),
                    max: WalkRequestState.maxDurationMinutes.toDouble(),
                    divisions:
                        (WalkRequestState.maxDurationMinutes -
                            WalkRequestState.minDurationMinutes) ~/
                        WalkRequestState.durationStepMinutes,
                    label: '$selectedMinutes min',
                    onChanged: (value) {
                      setModalState(() => minutes = value);
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('30 min'), Text('90 min')],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, selectedMinutes),
                      child: const Text('Usar esta duración'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final customSelected = !WalkRequestState.allowedDurations.contains(
      state.durationMinutes,
    );

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          children: WalkRequestState.allowedDurations.map((minutes) {
            final selected = minutes == state.durationMinutes;

            final base = state.hourlyRate * (minutes / 60);

            return Material(
              color: selected ? DogGoTheme.teal : DogGoTheme.card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => onSelected(minutes),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? DogGoTheme.teal : DogGoTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_walk_rounded,
                        color: selected ? Colors.white : DogGoTheme.teal,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _durationLabel(minutes),
                              style: DogGoTheme.body(
                                size: 12,
                                color: selected ? Colors.white : DogGoTheme.ink,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${base.toStringAsFixed(2)} base',
                              style: DogGoTheme.caption(
                                size: 9.5,
                                color: selected
                                    ? Colors.white.withValues(alpha: .75)
                                    : DogGoTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectCustomDuration(context),
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              customSelected
                  ? 'Personalizada · ${_durationLabel(state.durationMinutes)}'
                  : 'Elegir otra duración',
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: customSelected
                  ? DogGoTheme.tealLight
                  : DogGoTheme.card,
              side: BorderSide(
                color: customSelected ? DogGoTheme.teal : DogGoTheme.border,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _durationLabel(int minutes) {
    switch (minutes) {
      case 60:
        return '1 hora';
      case 90:
        return '1.5 horas';
      default:
        return '$minutes min';
    }
  }
}

class _ScheduleProgramCard extends StatelessWidget {
  final WalkRequestState state;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<WalkScheduleDraft> onRemove;

  const _ScheduleProgramCard({
    required this.state,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final walks = state.scheduledWalks;
    final grouped = <String, _ScheduleConfigGroup>{};
    for (final walk in walks) {
      final petIds = [...walk.petIds]..sort();
      final key = '${walk.durationMinutes}:${petIds.join("-")}';
      grouped
          .putIfAbsent(
            key,
            () => _ScheduleConfigGroup(
              durationMinutes: walk.durationMinutes,
              petIds: petIds,
            ),
          )
          .walks
          .add(walk);
    }
    final groups = grouped.values.toList()
      ..sort(
        (left, right) =>
            left.walks.first.startsAt.compareTo(right.walks.first.startsAt),
      );
    final groupLabel = groups.length == 1
        ? '1 grupo con la misma configuración'
        : '${groups.length} grupos con distinta configuración';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DogGoTheme.teal.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${walks.length} paseos en esta solicitud',
                      style: DogGoTheme.title(size: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      groupLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.caption(size: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'Cada fecha será un paseo independiente. DogGo los enviará juntos para que no repitas todo el formulario.',
              style: DogGoTheme.caption(
                size: 9.5,
                color: DogGoTheme.tealDark,
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...groups.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _ScheduleGroupCard(
                index: entry.$1,
                group: entry.$2,
                state: state,
                showDates: expanded || walks.length <= 2,
                onRemove: onRemove,
              ),
            ),
          ),
          if (walks.length > 2) ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  expanded
                      ? 'Ocultar fechas'
                      : 'Revisar las ${walks.length} fechas',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _shortDate(DateTime date) {
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _ScheduleConfigGroup {
  final int durationMinutes;
  final List<int> petIds;
  final List<WalkScheduleDraft> walks = [];

  _ScheduleConfigGroup({required this.durationMinutes, required this.petIds});
}

class _ScheduleGroupCard extends StatelessWidget {
  final int index;
  final _ScheduleConfigGroup group;
  final WalkRequestState state;
  final bool showDates;
  final ValueChanged<WalkScheduleDraft> onRemove;

  const _ScheduleGroupCard({
    required this.index,
    required this.group,
    required this.state,
    required this.showDates,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final pets = state.pets
        .where((pet) => group.petIds.contains(pet.id))
        .map((pet) => pet.name)
        .join(', ');
    final first = group.walks.first.startsAt;
    final last = group.walks.last.startsAt;
    final countLabel = group.walks.length == 1
        ? '1 paseo'
        : '${group.walks.length} paseos';
    final accent = index.isEven ? DogGoTheme.teal : DogGoTheme.purple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accent.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: DogGoTheme.label(size: 10, color: Colors.white),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$countLabel · ${group.durationMinutes} min',
                      style: DogGoTheme.body(size: 11, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pets,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.caption(
                        size: 9.5,
                        color: accent,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.walks.length == 1
                          ? _dateTimeLabel(first)
                          : '${_shortDate(first)}–${_shortDate(last)}',
                      style: DogGoTheme.caption(size: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDates) ...[
            const SizedBox(height: 10),
            ...group.walks.map(
              (walk) => _ScheduledWalkRow(
                walk: walk,
                state: state,
                onRemove: () => onRemove(walk),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _dateTimeLabel(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_ScheduleProgramCard._shortDate(date)} · $hour:$minute';
  }

  static String _shortDate(DateTime date) {
    return _ScheduleProgramCard._shortDate(date);
  }
}

class _ScheduledWalkRow extends StatelessWidget {
  final WalkScheduleDraft walk;
  final WalkRequestState state;
  final VoidCallback onRemove;

  const _ScheduledWalkRow({
    required this.walk,
    required this.state,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final date = walk.startsAt;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final pets = state.pets
        .where((pet) => walk.petIds.contains(pet.id))
        .map((pet) => pet.name)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 8, 4, 8),
        decoration: BoxDecoration(
          color: DogGoTheme.cream,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: DogGoTheme.teal,
              size: 17,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_ScheduleProgramCard._shortDate(date)} · $hour:$minute',
                    style: DogGoTheme.body(size: 11, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${walk.durationMinutes} min · $pets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.caption(size: 9.5),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar esta fecha',
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 15)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: DogGoTheme.subtitle(size: 10.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: DogGoTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onDefault;
  final VoidCallback onCurrent;
  final VoidCallback onMap;

  const _LocationCard({
    required this.state,
    required this.onDefault,
    required this.onCurrent,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final location = state.pickupLocation;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: location == null ? DogGoTheme.border : DogGoTheme.teal,
          width: location == null ? 1 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: DogGoTheme.teal,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location == null
                          ? 'Sin ubicación seleccionada'
                          : location.displayAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.title(size: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location == null
                          ? 'Elige una opción'
                          : location.address == 'Ubicación actual'
                          ? location.coordinatesLabel
                          : 'Punto de recogida seleccionado',
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                  ],
                ),
              ),
              if (location != null)
                const Icon(Icons.check_circle_rounded, color: DogGoTheme.teal),
            ],
          ),
          if (location != null) ...[
            const SizedBox(height: 13),
            DogGoMapPreview(
              latitud: location.latitude,
              longitud: location.longitude,
              height: 145,
              markerLabel: 'Punto de recogida',
              onTap: onMap,
            ),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              if (state.hasDefaultLocation) ...[
                Expanded(
                  child: _LocationButton(
                    icon: Icons.home_rounded,
                    label: 'Domicilio',
                    onTap: onDefault,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _LocationButton(
                  icon: state.loadingLocation
                      ? Icons.hourglass_top_rounded
                      : Icons.my_location_rounded,
                  label: state.loadingLocation ? 'Buscando' : 'Mi GPS',
                  onTap: state.loadingLocation ? null : onCurrent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LocationButton(
                  icon: Icons.map_outlined,
                  label: 'Mapa',
                  onTap: onMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _LocationButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      maxLength: 300,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'Ej. Choco necesita caminar despacio y lleva su correa azul.',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8, bottom: 70),
          child: Icon(Icons.notes_rounded, color: DogGoTheme.teal),
        ),
        filled: true,
        fillColor: DogGoTheme.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DogGoTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DogGoTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: DogGoTheme.teal, width: 1.5),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final WalkRequestState state;

  const _PriceSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final groups = <String, _WalkPriceGroup>{};
    for (final walk in state.effectiveScheduledWalks) {
      final price = state.priceForWalk(walk);
      final key =
          '${walk.durationMinutes}:${walk.petIds.length}:'
          '${price.toStringAsFixed(2)}';
      final group = groups.putIfAbsent(
        key,
        () => _WalkPriceGroup(
          durationMinutes: walk.durationMinutes,
          petCount: walk.petIds.length,
          pricePerWalk: price,
        ),
      );
      group.count++;
    }
    if (groups.isEmpty && state.hasSelectedPets) {
      final preview = _WalkPriceGroup(
        durationMinutes: state.durationMinutes,
        petCount: state.selectedPetCount,
        pricePerWalk: state.pricePerWalk,
      )..count = 1;
      groups['preview'] = preview;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.orange.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Desglose del precio', style: DogGoTheme.title(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Revisa cuánto cuesta cada paseo antes de solicitar.',
            style: DogGoTheme.caption(size: 10.5),
          ),
          const SizedBox(height: 15),
          _PriceRow(
            label: 'Tarifa del paseador',
            value: '\$${state.hourlyRate.toStringAsFixed(2)} / hora',
          ),
          if (groups.isNotEmpty) ...[
            const SizedBox(height: 13),
            ...groups.values.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _WalkPriceGroupCard(
                  group: group,
                  hourlyRate: state.hourlyRate,
                ),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: DogGoTheme.orange),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total estimado', style: DogGoTheme.title(size: 17)),
                    const SizedBox(height: 3),
                    Text(
                      state.walkCount == 1
                          ? '1 paseo programado'
                          : state.walkCount > 1
                          ? '${state.walkCount} paseos programados'
                          : 'Referencia para 1 paseo',
                      style: DogGoTheme.caption(size: 10),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${state.estimatedTotal.toStringAsFixed(2)}',
                style: DogGoTheme.title(size: 24, color: DogGoTheme.teal),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: DogGoTheme.muted,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'El backend confirmará el importe con la tarifa vigente del paseador.',
                  style: DogGoTheme.caption(size: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalkPriceGroup {
  final int durationMinutes;
  final int petCount;
  final double pricePerWalk;
  int count = 0;

  _WalkPriceGroup({
    required this.durationMinutes,
    required this.petCount,
    required this.pricePerWalk,
  });

  double get subtotal => pricePerWalk * count;
}

class _WalkPriceGroupCard extends StatelessWidget {
  final _WalkPriceGroup group;
  final double hourlyRate;

  const _WalkPriceGroupCard({required this.group, required this.hourlyRate});

  @override
  Widget build(BuildContext context) {
    final basePrice = hourlyRate * (group.durationMinutes / 60);
    final additionalPrice = group.pricePerWalk - basePrice;
    final walkLabel = group.count == 1 ? '1 paseo' : '${group.count} paseos';
    final petLabel = group.petCount == 1
        ? '1 mascota'
        : '${group.petCount} mascotas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DogGoTheme.orange.withValues(alpha: .22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$walkLabel · ${group.durationMinutes} min · $petLabel',
                  style: DogGoTheme.body(size: 10.5, weight: FontWeight.w900),
                ),
              ),
              Text(
                '\$${group.pricePerWalk.toStringAsFixed(2)} c/u',
                style: DogGoTheme.body(
                  size: 11,
                  color: DogGoTheme.teal,
                  weight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _PriceDetailRow(
            label:
                '${group.durationMinutes} min × \$${hourlyRate.toStringAsFixed(2)}/hora',
            value: '\$${basePrice.toStringAsFixed(2)}',
          ),
          if (group.petCount > 1) ...[
            const SizedBox(height: 5),
            _PriceDetailRow(
              label:
                  '${group.petCount - 1} ${group.petCount == 2 ? "mascota adicional" : "mascotas adicionales"} · 50%',
              value: '+ \$${additionalPrice.toStringAsFixed(2)}',
            ),
          ],
          if (group.count > 1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
            _PriceDetailRow(
              label:
                  '${group.count} × \$${group.pricePerWalk.toStringAsFixed(2)}',
              value: '\$${group.subtotal.toStringAsFixed(2)}',
              strong: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _PriceDetailRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.caption(
              size: 9.5,
              color: strong ? DogGoTheme.ink : DogGoTheme.muted,
              weight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: DogGoTheme.body(
            size: 10.5,
            weight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 11.5, color: DogGoTheme.ink),
          ),
        ),
        Text(value, style: DogGoTheme.body(size: 12, weight: FontWeight.w800)),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onSubmit;

  const _SubmitBar({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final count = state.selectedPetCount;
    final walkCount = state.walkCount;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 13, 20, 14),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          border: const Border(top: BorderSide(color: DogGoTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: state.canSubmit ? onSubmit : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: DogGoTheme.teal,
            disabledBackgroundColor: DogGoTheme.disabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: state.saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pets_rounded),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        count == 0
                            ? 'Selecciona una mascota'
                            : walkCount > 1
                            ? 'Solicitar $walkCount paseos'
                            : count == 1
                            ? 'Solicitar paseo'
                            : 'Solicitar para $count mascotas',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 12),
                      Text(
                        '\$${state.estimatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final Color color;

  const _Initials({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: DogGoTheme.title(size: 19, color: color)),
    );
  }
}
