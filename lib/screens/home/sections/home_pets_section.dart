import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_empty_view.dart';
import '../../../shared/widgets/doggo_error_view.dart';
import '../../../shared/widgets/doggo_skeleton_card.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../widgets/home_section_title.dart';

class HomePetItem {
  final String name;
  final String breed;
  final String age;
  final String imageUrl;
  final String activity;
  final VoidCallback onTap;
  final VoidCallback onRequestWalk;

  const HomePetItem({
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.activity,
    required this.onTap,
    required this.onRequestWalk,
  });
}

class HomePetsSection extends StatelessWidget {
  final bool loading;
  final String? errorMessage;
  final List<HomePetItem> pets;
  final VoidCallback onSeeAll;
  final VoidCallback onAddPet;
  final VoidCallback onRetry;

  const HomePetsSection({
    super.key,
    required this.loading,
    required this.pets,
    required this.onSeeAll,
    required this.onAddPet,
    required this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DogGoSpacing.screenHorizontal,
        DogGoSpacing.sectionGap,
        DogGoSpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: 'Mis perros',
            subtitle: pets.isEmpty
                ? 'Tu familia empieza aquí'
                : '${pets.length} ${pets.length == 1 ? 'perfil disponible' : 'perfiles disponibles'}',
            actionText: pets.isEmpty ? 'Agregar' : 'Ver todas',
            onAction: pets.isEmpty ? onAddPet : onSeeAll,
          ),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const _PetsLoading();
    }

    if (errorMessage != null) {
      return DogGoErrorView(
        title: 'No pudimos cargar tus mascotas',
        message: errorMessage!,
        icon: Icons.pets_outlined,
        onRetry: onRetry,
        compact: true,
      );
    }

    if (pets.isEmpty) {
      return DogGoEmptyView(
        title: 'Agrega a tu primer perro',
        message:
            'Crea su perfil con fotografía y datos importantes para solicitar paseos con seguridad.',
        icon: Icons.add_a_photo_rounded,
        actionText: 'Agregar mi primer perro',
        onAction: onAddPet,
        color: DogGoTheme.orange,
        background: DogGoTheme.orangeLight,
      );
    }

    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pets.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 11),
        itemBuilder: (context, index) {
          if (index == pets.length) {
            return _AddPetCard(onTap: onAddPet);
          }

          return _PetCard(pet: pets[index]);
        },
      ),
    );
  }
}

class _PetsLoading extends StatelessWidget {
  const _PetsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 252,
      child: Row(
        children: [
          Expanded(child: DogGoSkeletonCard(height: 252)),
          SizedBox(width: 13),
          Expanded(child: DogGoSkeletonCard(height: 252)),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final HomePetItem pet;

  const _PetCard({required this.pet});

  bool get _hasImage {
    final value = pet.imageUrl.trim();

    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 214,
      child: Semantics(
        container: true,
        label: '${pet.name}. ${pet.breed}. ${pet.age}. ${pet.activity}.',
        child: Material(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(DogGoRadius.large),
          child: Ink(
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(DogGoRadius.large),
              border: Border.all(color: DogGoTheme.border),
              boxShadow: DogGoTheme.softShadow(opacity: .04, blur: 18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DogGoRadius.large - 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: pet.onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 116,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _hasImage
                                    ? Image.network(
                                        pet.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) {
                                          return const _DogPlaceholder();
                                        },
                                      )
                                    : const _DogPlaceholder(),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Color(0x8A000000),
                                      ],
                                      stops: [.48, 1],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 13,
                                  right: 44,
                                  bottom: 10,
                                  child: Text(
                                    pet.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DogGoTheme.title(
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .92,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_outward_rounded,
                                      size: 17,
                                      color: DogGoTheme.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.breed.trim().isEmpty
                                      ? 'Compañero DogGo'
                                      : pet.breed,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DogGoTheme.body(
                                    size: 11.5,
                                    color: DogGoTheme.ink,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cake_outlined,
                                      size: 15,
                                      color: DogGoTheme.teal,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        pet.age,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DogGoTheme.subtitle(size: 10),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event_available_outlined,
                                      size: 15,
                                      color: DogGoTheme.orange,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        pet.activity,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DogGoTheme.subtitle(size: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: DogGoTheme.border)),
                    ),
                    child: InkWell(
                      onTap: pet.onRequestWalk,
                      child: const SizedBox(
                        height: 42,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_walk_rounded,
                              size: 18,
                              color: DogGoTheme.teal,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Solicitar paseo',
                              style: TextStyle(
                                color: DogGoTheme.teal,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Semantics(
        button: true,
        label: 'Agregar mascota',
        child: Material(
          color: DogGoTheme.tealLight,
          borderRadius: BorderRadius.circular(DogGoRadius.large),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DogGoRadius.large),
            child: Ink(
              decoration: BoxDecoration(
                color: DogGoTheme.tealLight,
                borderRadius: BorderRadius.circular(DogGoRadius.large),
                border: Border.all(
                  color: DogGoTheme.teal.withValues(alpha: .16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: DogGoTheme.card,
                        shape: BoxShape.circle,
                        boxShadow: DogGoTheme.softShadow(
                          opacity: .05,
                          blur: 14,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: DogGoTheme.teal,
                        size: 29,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      'Agregar\notro perro',
                      textAlign: TextAlign.center,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Crear nuevo perfil',
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DogPlaceholder extends StatelessWidget {
  const _DogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DogGoTheme.tealLight,
      alignment: Alignment.center,
      child: const Icon(Icons.pets_rounded, color: DogGoTheme.teal, size: 48),
    );
  }
}
