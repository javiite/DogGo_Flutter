import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'registrar_perro_screen.dart';
import 'seleccionar_ubicacion_screen.dart';
import 'walkers/models/walker.dart';
import 'walks/models/pickup_location.dart';
import 'walks/walk_request_controller.dart';
import 'walks/walk_request_state.dart';

class CrearPaseoScreen extends StatefulWidget {
  final Map<String, dynamic> paseador;

  const CrearPaseoScreen({
    super.key,
    required this.paseador,
  });

  @override
  State<CrearPaseoScreen> createState() =>
      _CrearPaseoScreenState();
}

class _CrearPaseoScreenState
    extends State<CrearPaseoScreen> {
  late final WalkRequestController _controller;

  final TextEditingController _notesController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = WalkRequestController(
      walkerData: widget.paseador,
    );

    _controller.initialize();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectSchedule() async {
    final now = DateTime.now();
    final current =
        _controller.state.scheduledAt;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 180),
      ),
      helpText: 'Selecciona el día del paseo',
      cancelText: 'Cancelar',
      confirmText: 'Continuar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: DogGoTheme.teal,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final initialDateTime = current ??
        now.add(const Duration(hours: 1));

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        initialDateTime,
      ),
      helpText: 'Selecciona la hora',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: DogGoTheme.teal,
                    ),
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
      _showMessage(
        'Selecciona una fecha y hora futuras.',
      );
      return;
    }

    _controller.setSchedule(result);
  }

  Future<void> _openMap() async {
    final current =
        _controller.state.pickupLocation;

    final result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: current == null
              ? null
              : LatLng(
                  current.latitude,
                  current.longitude,
                ),
          textoInicial: current?.displayAddress,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final error =
        _controller.applyMapResult(result);

    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _useCurrentLocation() async {
    final error =
        await _controller.useCurrentLocation();

    if (!mounted) {
      return;
    }

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      'Ubicación actual seleccionada.',
    );
  }

  void _useDefaultLocation() {
    final error =
        _controller.useDefaultLocation();

    if (error != null) {
      _showMessage(error);
      return;
    }

    _showMessage(
      'Ubicación predeterminada seleccionada.',
    );
  }

  Future<void> _registerPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RegistrarPerroScreen(),
      ),
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
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      result.message,
      success: result.success,
    );

    if (result.success) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success
              ? DogGoTheme.teal
              : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          bottomNavigationBar:
              state.loading || state.error != null
                  ? null
                  : _SubmitBottomBar(
                      state: state,
                      onSubmit: _submit,
                    ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _RequestTopBar(),
                Expanded(
                  child: _buildBody(state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    WalkRequestState state,
  ) {
    if (state.loading) {
      return const DogGoLoadingView(
        message:
            'Preparando tu solicitud...',
      );
    }

    if (state.error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(
          DogGoSpacing.screenHorizontal,
        ),
        child: DogGoErrorView(
          title:
              'No pudimos preparar el paseo',
          message: state.error!,
          icon: Icons.directions_walk_outlined,
          onRetry: _controller.initialize,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.initialize,
      color: DogGoTheme.teal,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          18,
          DogGoSpacing.screenHorizontal,
          140,
        ),
        children: [
          _RequestIntroduction(
            walker: state.walker,
            photoUrl: state.walkerPhotoUrl,
          ),
          const SizedBox(height: 26),
          _StepTitle(
            number: 1,
            title: 'Elige a tu mascota',
            subtitle:
                'Selecciona quién saldrá a pasear',
            completed:
                state.selectedPet != null,
          ),
          const SizedBox(height: 13),
          if (state.pets.isEmpty)
            _NoPetsCard(
              onRegister: _registerPet,
            )
          else
            _PetSelector(
              state: state,
              onSelected:
                  _controller.selectPet,
            ),
          const SizedBox(height: 28),
          _StepTitle(
            number: 2,
            title: 'Duración',
            subtitle:
                '¿Cuánto tiempo necesita?',
            completed: true,
          ),
          const SizedBox(height: 13),
          _DurationSelector(
            selectedMinutes:
                state.durationMinutes,
            hourlyRate: state.hourlyRate,
            onSelected:
                _controller.selectDuration,
          ),
          const SizedBox(height: 28),
          _StepTitle(
            number: 3,
            title: 'Fecha y hora',
            subtitle:
                'Programa el momento del paseo',
            completed:
                state.scheduledAt != null,
          ),
          const SizedBox(height: 13),
          _ScheduleCard(
            state: state,
            onTap: _selectSchedule,
          ),
          const SizedBox(height: 28),
          _StepTitle(
            number: 4,
            title: 'Punto de recogida',
            subtitle:
                'Indica dónde recogerán a tu mascota',
            completed:
                state.hasPickupLocation,
          ),
          const SizedBox(height: 13),
          _LocationSection(
            state: state,
            onOpenMap: _openMap,
            onCurrentLocation:
                _useCurrentLocation,
            onDefaultLocation:
                _useDefaultLocation,
          ),
          const SizedBox(height: 28),
          _StepTitle(
            number: 5,
            title: 'Indicaciones',
            subtitle:
                'Agrega información útil para el paseador',
            completed: true,
          ),
          const SizedBox(height: 13),
          _NotesField(
            controller: _notesController,
          ),
          const SizedBox(height: 28),
          _RequestSummary(
            state: state,
          ),
        ],
      ),
    );
  }
}

class _RequestTopBar extends StatelessWidget {
  const _RequestTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: const BoxDecoration(
        color: DogGoTheme.card,
        border: Border(
          bottom: BorderSide(
            color: DogGoTheme.border,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                Navigator.pop(context),
            tooltip: 'Regresar',
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Solicitar paseo',
              style: DogGoTheme.title(size: 19),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.tealLight,
              borderRadius: BorderRadius.circular(
                DogGoRadius.pill,
              ),
            ),
            child: Text(
              '5 pasos',
              style: DogGoTheme.caption(
                size: 10,
                color: DogGoTheme.teal,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestIntroduction extends StatelessWidget {
  final Walker walker;
  final String? photoUrl;

  const _RequestIntroduction({
    required this.walker,
    required this.photoUrl,
  });

  bool get _hasPhoto {
    final value = photoUrl?.trim() ?? '';

    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.teal,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: .14,
              ),
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: _hasPhoto
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return _WalkerPlaceholder(
                        initials: walker.initials,
                      );
                    },
                  )
                : _WalkerPlaceholder(
                    initials: walker.initials,
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Paseo con',
                  style: DogGoTheme.caption(
                    size: 10,
                    color: Colors.white.withValues(
                      alpha: .7,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        walker.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.title(
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (walker.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF9BE4D2),
                        size: 18,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  walker.rateLabel,
                  style: DogGoTheme.body(
                    size: 11.5,
                    color: Colors.white.withValues(
                      alpha: .82,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.pets_rounded,
            color: Colors.white,
            size: 25,
          ),
        ],
      ),
    );
  }
}

class _WalkerPlaceholder extends StatelessWidget {
  final String initials;

  const _WalkerPlaceholder({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final bool completed;

  const _StepTitle({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? DogGoTheme.teal
                : DogGoTheme.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed
                  ? DogGoTheme.teal
                  : DogGoTheme.border,
            ),
          ),
          child: completed
              ? const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: Colors.white,
                )
              : Text(
                  '$number',
                  style: DogGoTheme.body(
                    size: 11,
                    weight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DogGoTheme.title(size: 18),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style:
                    DogGoTheme.subtitle(size: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PetSelector extends StatelessWidget {
  final WalkRequestState state;
  final ValueChanged<int> onSelected;

  const _PetSelector({
    required this.state,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.pets.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final pet = state.pets[index];
          final selected =
              pet.id == state.selectedPetId;

          return _PetChoiceCard(
            name: pet.name,
            breed: pet.breed,
            initials: pet.initials,
            photoUrl: state.petPhotoUrl(pet),
            selected: selected,
            onTap: () => onSelected(pet.id),
          );
        },
      ),
    );
  }
}

class _PetChoiceCard extends StatelessWidget {
  final String name;
  final String breed;
  final String initials;
  final String? photoUrl;
  final bool selected;
  final VoidCallback onTap;

  const _PetChoiceCard({
    required this.name,
    required this.breed,
    required this.initials,
    required this.photoUrl,
    required this.selected,
    required this.onTap,
  });

  bool get _hasPhoto {
    final value = photoUrl?.trim() ?? '';

    return value.startsWith('http://') ||
        value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
      child: Material(
        color: selected
            ? DogGoTheme.tealLight
            : DogGoTheme.card,
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            DogGoRadius.large,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                DogGoRadius.large,
              ),
              border: Border.all(
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 68,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: DogGoTheme.card,
                    borderRadius: BorderRadius.circular(
                      DogGoRadius.medium,
                    ),
                  ),
                  child: _hasPhoto
                      ? Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) {
                            return _PetInitials(
                              initials: initials,
                            );
                          },
                        )
                      : _PetInitials(
                          initials: initials,
                        ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.title(
                          size: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        breed,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: DogGoTheme.caption(
                          size: 9.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons
                                .radio_button_unchecked_rounded,
                        color: selected
                            ? DogGoTheme.teal
                            : DogGoTheme.muted,
                        size: 18,
                      ),
                    ],
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

class _PetInitials extends StatelessWidget {
  final String initials;

  const _PetInitials({
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: DogGoTheme.title(
          size: 16,
          color: DogGoTheme.teal,
        ),
      ),
    );
  }
}

class _NoPetsCard extends StatelessWidget {
  final VoidCallback onRegister;

  const _NoPetsCard({
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Icon(
            Icons.pets_outlined,
            color: DogGoTheme.teal,
            size: 38,
          ),
          const SizedBox(height: 9),
          Text(
            'No tienes mascotas registradas',
            style: DogGoTheme.title(size: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'Registra una mascota antes de solicitar el paseo.',
            textAlign: TextAlign.center,
            style: DogGoTheme.subtitle(size: 11.5),
          ),
          const SizedBox(height: 13),
          OutlinedButton.icon(
            onPressed: onRegister,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label:
                const Text('Registrar mascota'),
          ),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int selectedMinutes;
  final double hourlyRate;
  final ValueChanged<int> onSelected;

  const _DurationSelector({
    required this.selectedMinutes,
    required this.hourlyRate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.15,
      children:
          WalkRequestState.allowedDurations.map(
        (minutes) {
          return _DurationChoice(
            minutes: minutes,
            selected:
                minutes == selectedMinutes,
            estimatedPrice:
                hourlyRate * (minutes / 60),
            onTap: () => onSelected(minutes),
          );
        },
      ).toList(),
    );
  }
}

class _DurationChoice extends StatelessWidget {
  final int minutes;
  final bool selected;
  final double estimatedPrice;
  final VoidCallback onTap;

  const _DurationChoice({
    required this.minutes,
    required this.selected,
    required this.estimatedPrice,
    required this.onTap,
  });

  String get _label {
    if (minutes == 60) {
      return '1 hora';
    }

    if (minutes == 90) {
      return '1.5 horas';
    }

    return '$minutes min';
  }

  IconData get _icon {
    switch (minutes) {
      case 30:
        return Icons.flash_on_outlined;
      case 45:
        return Icons.directions_walk_rounded;
      case 60:
        return Icons.route_outlined;
      default:
        return Icons.local_fire_department_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DogGoTheme.tealLight
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              DogGoRadius.medium,
            ),
            border: Border.all(
              color: selected
                  ? DogGoTheme.teal
                  : DogGoTheme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                color: selected
                    ? DogGoTheme.teal
                    : DogGoTheme.muted,
                size: 23,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: DogGoTheme.body(
                        size: 12,
                        color: selected
                            ? DogGoTheme.teal
                            : DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '\$${estimatedPrice.toStringAsFixed(2)}',
                      style: DogGoTheme.caption(
                        size: 9.5,
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
  }
}

class _ScheduleCard extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected =
        state.scheduledAt != null;

    return _ActionCard(
      icon: Icons.calendar_month_outlined,
      iconColor: selected
          ? DogGoTheme.teal
          : DogGoTheme.orange,
      iconBackground: selected
          ? DogGoTheme.tealLight
          : DogGoTheme.orangeLight,
      title: selected
          ? 'Paseo programado'
          : 'Seleccionar fecha y hora',
      subtitle: state.scheduleLabel,
      trailingIcon:
          Icons.chevron_right_rounded,
      onTap: onTap,
    );
  }
}

class _LocationSection extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onOpenMap;
  final VoidCallback onCurrentLocation;
  final VoidCallback onDefaultLocation;

  const _LocationSection({
    required this.state,
    required this.onOpenMap,
    required this.onCurrentLocation,
    required this.onDefaultLocation,
  });

  @override
  Widget build(BuildContext context) {
    final location =
        state.pickupLocation;

    return Column(
      children: [
        _ActionCard(
          icon: Icons.location_on_outlined,
          iconColor: location == null
              ? DogGoTheme.orange
              : DogGoTheme.teal,
          iconBackground: location == null
              ? DogGoTheme.orangeLight
              : DogGoTheme.tealLight,
          title: location == null
              ? 'Seleccionar en el mapa'
              : 'Lugar seleccionado',
          subtitle: location == null
              ? 'Abre el mapa para elegir el punto exacto'
              : location.displayAddress,
          trailingIcon:
              Icons.chevron_right_rounded,
          onTap: onOpenMap,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SmallLocationButton(
                icon: Icons.my_location_rounded,
                label: 'Mi ubicación',
                loading:
                    state.loadingLocation,
                onPressed: state.loadingLocation
                    ? null
                    : onCurrentLocation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallLocationButton(
                icon: Icons.home_outlined,
                label: 'Predeterminada',
                enabled:
                    state.hasDefaultLocation,
                onPressed:
                    state.hasDefaultLocation
                        ? onDefaultLocation
                        : null,
              ),
            ),
          ],
        ),
        if (location != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: DogGoTheme.greenLight,
              borderRadius: BorderRadius.circular(
                DogGoRadius.medium,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: DogGoTheme.green,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Coordenadas listas: '
                    '${location.coordinatesLabel}',
                    style: DogGoTheme.caption(
                      size: 10,
                      color: DogGoTheme.green,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallLocationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback? onPressed;

  const _SmallLocationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: loading
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 5,
      maxLength: 300,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Indicaciones opcionales',
        hintText:
            'Ejemplo: tocar el timbre, llevar arnés azul o evitar otros perros.',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 66),
          child: Icon(
            Icons.notes_rounded,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              DogGoRadius.large,
            ),
            border: Border.all(
              color: DogGoTheme.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(
                    DogGoRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DogGoTheme.body(
                        size: 13,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DogGoTheme.subtitle(
                        size: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(
                trailingIcon,
                color: DogGoTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestSummary extends StatelessWidget {
  final WalkRequestState state;

  const _RequestSummary({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final petName =
        state.selectedPet?.name ??
            'Sin mascota';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            DogGoTheme.orangeLight,
            DogGoTheme.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          DogGoRadius.large,
        ),
        border: Border.all(
          color: DogGoTheme.orange.withValues(
            alpha: .18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: DogGoTheme.card,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: DogGoTheme.orange,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Resumen de solicitud',
                  style:
                      DogGoTheme.title(size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Mascota',
            value: petName,
          ),
          const SizedBox(height: 9),
          _SummaryRow(
            label: 'Duración',
            value: state.durationLabel,
          ),
          const SizedBox(height: 9),
          _SummaryRow(
            label: 'Fecha',
            value: state.scheduleLabel,
          ),
          const SizedBox(height: 9),
          _SummaryRow(
            label: 'Recogida',
            value: state.pickupLocation
                    ?.displayAddress ??
                'Sin seleccionar',
            valueColor:
                state.hasPickupLocation
                    ? DogGoTheme.ink
                    : DogGoTheme.red,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total estimado',
                  style: DogGoTheme.body(
                    size: 12.5,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\$${state.estimatedTotal.toStringAsFixed(2)}',
                style: DogGoTheme.title(
                  size: 20,
                  color: DogGoTheme.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sujeto a confirmación del paseo',
              style:
                  DogGoTheme.caption(size: 9.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor = DogGoTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: DogGoTheme.caption(
              size: 10.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DogGoTheme.body(
              size: 11,
              color: valueColor,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitBottomBar extends StatelessWidget {
  final WalkRequestState state;
  final VoidCallback onSubmit;

  const _SubmitBottomBar({
    required this.state,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          10,
          DogGoSpacing.screenHorizontal,
          12,
        ),
        decoration: BoxDecoration(
          color: DogGoTheme.card.withValues(
            alpha: .98,
          ),
          border: const Border(
            top: BorderSide(
              color: DogGoTheme.border,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: .04,
              ),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: state.saving
                ? null
                : onSubmit,
            icon: state.saving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
            label: Text(
              state.saving
                  ? 'Enviando solicitud...'
                  : 'Confirmar · '
                      '\$${state.estimatedTotal.toStringAsFixed(2)}',
            ),
          ),
        ),
      ),
    );
  }
}