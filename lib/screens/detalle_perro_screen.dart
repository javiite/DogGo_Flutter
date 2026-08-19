import 'package:flutter/material.dart';

import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'editar_perro_screen.dart';
import 'pets/models/pet.dart';
import 'pets/pet_detail_controller.dart';
import 'pets/pet_detail_state.dart';
import 'pets/widgets/pet_gallery_section.dart';

class DetallePerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const DetallePerroScreen({super.key, required this.perro});

  @override
  State<DetallePerroScreen> createState() => _DetallePerroScreenState();
}

class _DetallePerroScreenState extends State<DetallePerroScreen> {
  late final PetDetailController _controller;

  bool _allowPop = false;

  @override
  void initState() {
    super.initState();

    _controller = PetDetailController(initialData: widget.perro)..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (_allowPop || !mounted) return;

    setState(() {
      _allowPop = true;
    });

    Navigator.pop(context, _controller.state.changed);
  }

  Future<void> _openEdit(Pet pet) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EditarPerroScreen(perro: pet.rawData),
      ),
    );

    if (!mounted) return;

    if (updated == true) {
      await _controller.markChangedAndRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _close();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: 'Volver',
                onPressed: _close,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(state.pet?.name ?? 'Mascota'),
              actions: [
                IconButton(
                  tooltip: 'Actualizar información',
                  onPressed: state.loading ? null : _controller.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: DogGoSpacing.sm),
              ],
            ),
            body: _buildBody(state),
          ),
        );
      },
    );
  }

  Widget _buildBody(PetDetailState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Cargando información...');
    }

    if (state.error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(
            title: 'No pudimos cargar la mascota',
            message: state.error!,
            onRetry: _controller.refresh,
          ),
        ),
      );
    }

    final pet = state.pet;

    if (pet == null) {
      return DogGoErrorView(
        message: 'No encontramos información de esta mascota.',
        onRetry: _controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.md,
          DogGoSpacing.screenHorizontal,
          DogGoSpacing.xxl,
        ),
        children: [
          _PetHero(
            pet: pet,
            photoUrl: state.photoUrl,
            onEdit: () => _openEdit(pet),
          ),
          const SizedBox(height: DogGoSpacing.md),
          PetGallerySection(state: state, controller: _controller),
          const SizedBox(height: DogGoSpacing.md),
          _buildGeneralInformation(pet),
          const SizedBox(height: DogGoSpacing.md),
          _buildBehavior(pet),
          const SizedBox(height: DogGoSpacing.md),
          _buildSafety(pet),
          const SizedBox(height: DogGoSpacing.md),
          _buildNotes(pet),
          const SizedBox(height: DogGoSpacing.lg),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _openEdit(pet),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar información'),
            ),
          ),
          const SizedBox(height: DogGoSpacing.md),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _close,
              child: const Text('Volver'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralInformation(Pet pet) {
    return _DetailCard(
      title: 'Información general',
      subtitle: 'Datos principales de tu mascota.',
      icon: Icons.pets_outlined,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.badge_outlined,
            title: 'Nombre',
            value: pet.name,
          ),
          _InformationRow(
            icon: Icons.category_outlined,
            title: 'Raza',
            value: pet.breed,
          ),
          _InformationRow(
            icon: Icons.cake_outlined,
            title: 'Edad',
            value: pet.ageLabel,
          ),
          _InformationRow(
            icon: Icons.straighten_rounded,
            title: 'Tamaño',
            value: pet.size,
          ),
          _InformationRow(
            icon: Icons.monitor_weight_outlined,
            title: 'Peso',
            value: pet.weight == null
                ? 'Sin registrar'
                : '${pet.weight!.toStringAsFixed(1)} kg',
          ),
          _InformationRow(
            icon: Icons.pets_outlined,
            title: 'Sexo',
            value: pet.sex ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.health_and_safety_outlined,
            title: 'Esterilizado',
            value: _yesNo(pet.sterilized),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBehavior(Pet pet) {
    return _DetailCard(
      title: 'Personalidad y convivencia',
      subtitle: 'Lo que el paseador debe conocer antes de salir.',
      icon: Icons.psychology_alt_outlined,
      iconColor: DogGoTheme.teal,
      iconBackground: DogGoTheme.tealLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.sentiment_satisfied_alt_rounded,
            title: 'Temperamento',
            value: pet.temperament ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.bolt_rounded,
            title: 'Energía',
            value: pet.energyLevel ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.route_outlined,
            title: 'Con correa',
            value: pet.leashBehavior ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.pets_outlined,
            title: 'Con perros',
            value: _yesNo(pet.socialWithDogs),
          ),
          _InformationRow(
            icon: Icons.person_outline_rounded,
            title: 'Con personas',
            value: _yesNo(pet.socialWithPeople),
          ),
          _InformationRow(
            icon: Icons.child_care_outlined,
            title: 'Con niños',
            value: _yesNo(pet.socialWithChildren),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSafety(Pet pet) {
    return _DetailCard(
      title: 'Seguridad durante el paseo',
      subtitle: 'Precauciones e indicaciones importantes.',
      icon: Icons.shield_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.warning_amber_rounded,
            title: 'Reactivo',
            value: _yesNo(pet.reactive),
          ),
          _InformationRow(
            icon: Icons.directions_run_rounded,
            title: 'Riesgo de escape',
            value: _yesNo(pet.escapeRisk),
          ),
          _InformationRow(
            icon: Icons.flash_on_outlined,
            title: 'Miedos o detonantes',
            value: pet.fearsTriggers ?? 'Sin registrar',
          ),
          _InformationRow(
            icon: Icons.record_voice_over_outlined,
            title: 'Comandos conocidos',
            value: pet.knownCommands ?? 'Sin registrar',
            last: true,
          ),
        ],
      ),
    );
  }

  String _yesNo(bool? value) {
    if (value == null) return 'Sin registrar';
    return value ? 'Sí' : 'No';
  }

  Widget _buildNotes(Pet pet) {
    final hasNotes = pet.notes.trim().isNotEmpty;

    return _DetailCard(
      title: 'Notas y cuidados',
      subtitle: 'Información importante para sus paseadores.',
      icon: Icons.notes_outlined,
      iconColor: DogGoTheme.orange,
      iconBackground: DogGoTheme.orangeLight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DogGoSpacing.md),
        decoration: BoxDecoration(
          color: hasNotes ? DogGoTheme.orangeLight : DogGoTheme.cream,
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
        ),
        child: Text(
          hasNotes
              ? pet.notes
              : 'Todavía no agregaste notas para esta mascota.',
          style: DogGoTheme.body(
            size: 13.5,
            color: hasNotes ? DogGoTheme.ink : DogGoTheme.muted,
            weight: hasNotes ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PetHero extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;
  final VoidCallback onEdit;

  const _PetHero({
    required this.pet,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 270,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'pet-photo-${pet.id}',
                  child: _HeroPhoto(pet: pet, photoUrl: photoUrl),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xB3000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.42, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: DogGoSpacing.cardPadding,
                  right: DogGoSpacing.cardPadding,
                  bottom: DogGoSpacing.cardPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DogGoTheme.title(
                                size: 29,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: DogGoSpacing.xs),
                            Text(
                              pet.shortDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DogGoTheme.subtitle(
                                size: 13.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: DogGoSpacing.compactGap),
                      IconButton.filled(
                        tooltip: 'Editar mascota',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: DogGoTheme.teal,
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
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

class _HeroPhoto extends StatelessWidget {
  final Pet pet;
  final String? photoUrl;

  const _HeroPhoto({required this.pet, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _PetPlaceholder(initials: pet.initials);
        },
      );
    }

    return _PetPlaceholder(initials: pet.initials);
  }
}

class _PetPlaceholder extends StatelessWidget {
  final String initials;

  const _PetPlaceholder({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: DogGoTheme.display(size: 54, color: DogGoTheme.teal),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DogGoSpacing.cardPadding),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(DogGoRadius.medium),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: DogGoSpacing.compactGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: DogGoTheme.subtitle(size: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DogGoSpacing.largeGap),
          child,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool last;

  const _InformationRow({
    required this.icon,
    required this.title,
    required this.value,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 11, bottom: last ? 0 : 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: DogGoTheme.divider)),
      ),
      child: Row(
        children: [
          Icon(icon, color: DogGoTheme.teal, size: 20),
          const SizedBox(width: DogGoSpacing.compactGap),
          Expanded(
            child: Text(
              title,
              style: DogGoTheme.body(size: 13, color: DogGoTheme.muted),
            ),
          ),
          const SizedBox(width: DogGoSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DogGoTheme.body(size: 13.5, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
