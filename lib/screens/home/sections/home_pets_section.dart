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
  final VoidCallback onTap;

  const HomePetItem({
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.onTap,
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
            title: 'Tus mascotas',
            subtitle: pets.isEmpty
                ? 'Registra a tu compañero'
                : '${pets.length} ${pets.length == 1 ? 'compañero registrado' : 'compañeros registrados'}',
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
        title: 'Agrega a tu primera mascota',
        message: 'Sube su foto y completa sus datos para verla en tu inicio.',
        icon: Icons.add_a_photo_rounded,
        actionText: 'Agregar mascota',
        onAction: onAddPet,
        color: DogGoTheme.orange,
        background: DogGoTheme.orangeLight,
        compact: true,
      );
    }

    return SizedBox(
      height: 196,
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
      height: 196,
      child: Row(
        children: [
          Expanded(child: DogGoSkeletonCard(height: 196)),
          SizedBox(width: 13),
          Expanded(child: DogGoSkeletonCard(height: 196)),
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
      width: 158,
      child: Semantics(
        button: true,
        label: 'Ver información de ${pet.name}',
        child: Material(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(DogGoRadius.large),
          child: InkWell(
            onTap: pet.onTap,
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
                    SizedBox(
                      height: 118,
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
                                colors: [Colors.transparent, Color(0x8A000000)],
                                stops: [.48, 1],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 10,
                            bottom: 10,
                            child: Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DogGoTheme.title(
                                size: 17,
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
                                color: Colors.white.withValues(alpha: .92),
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
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
                                weight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
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
                                    style: DogGoTheme.body(
                                      size: 10,
                                      color: DogGoTheme.muted,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 158,
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
                      'Agregar\nmascota',
                      textAlign: TextAlign.center,
                      style: DogGoTheme.body(
                        size: 14,
                        color: DogGoTheme.ink,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Nuevo perfil',
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
