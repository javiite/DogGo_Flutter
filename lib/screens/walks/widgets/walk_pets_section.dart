import 'package:flutter/material.dart';

import '../../../theme/doggo_theme.dart';
import '../../pets/widgets/pet_behavior_profile.dart';
import '../models/walk_pet.dart';
import '../walk_detail_controller.dart';
import '../walk_detail_state.dart';
import 'edit_walk_pets_sheet.dart';

class WalkPetsSection extends StatelessWidget {
  final WalkDetailState state;
  final WalkDetailController controller;
  final bool canViewPetProfiles;

  const WalkPetsSection({
    super.key,
    required this.state,
    required this.controller,
    this.canViewPetProfiles = true,
  });

  @override
  Widget build(BuildContext context) {
    final walk = state.walk;

    if (walk == null || walk.pets.isEmpty) {
      return const SizedBox.shrink();
    }

    final pets = walk.requestedPets.isNotEmpty ? walk.requestedPets : walk.pets;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: walk.hasPendingPetProposal
              ? DogGoTheme.orange.withValues(alpha: .45)
              : DogGoTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.pets_rounded, color: DogGoTheme.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pets.length == 1
                          ? 'Mascota del paseo'
                          : 'Mascotas del paseo',
                      style: DogGoTheme.title(size: 17),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pets.length == 1
                          ? '1 mascota solicitada'
                          : '${pets.length} mascotas solicitadas',
                      style: DogGoTheme.subtitle(size: 10.5),
                    ),
                  ],
                ),
              ),
              if (walk.hasPendingPetProposal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.orangeLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Cambio pendiente',
                    style: DogGoTheme.caption(
                      size: 9.5,
                      color: DogGoTheme.orange,
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          ...pets.map(
            (pet) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _WalkPetRow(
                pet: pet,
                baseUrl: state.baseUrl,
                proposalPending: walk.hasPendingPetProposal,
                onViewProfile: canViewPetProfiles
                    ? () => PetBehaviorProfile.show(
                        context,
                        pet: pet,
                        baseUrl: state.baseUrl,
                      )
                    : null,
              ),
            ),
          ),

          if (walk.hasPendingPetProposal) ...[
            const SizedBox(height: 8),
            _ProposalSummary(state: state),
          ],

          const SizedBox(height: 14),
          if (state.walk!.hasPendingPetProposal)
            _PriceInformation(state: state),
          if (state.canEditRequestedPets) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: state.acting
                  ? null
                  : () => _openOwnerPetEditor(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Editar mascotas de la solicitud'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],

          if (state.canProposePetChange) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: state.acting ? null : () => _openProposal(context),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Proponer cambio de mascotas'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],

          if (state.canRespondPetChange) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.acting
                        ? null
                        : () => _respond(context, accept: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DogGoTheme.red,
                      side: const BorderSide(color: DogGoTheme.red),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.acting
                        ? null
                        : () => _respond(context, accept: true),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Aceptar cambio'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openOwnerPetEditor(BuildContext context) async {
    final walk = state.walk;

    if (walk == null) {
      return;
    }

    final selectedIds = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: .84,
          child: EditWalkPetsSheet(
            initialSelectedIds: walk.requestedPets
                .map((pet) => pet.id)
                .where((id) => id > 0)
                .toSet(),
            baseUrl: state.baseUrl,
          ),
        );
      },
    );

    if (selectedIds == null || !context.mounted) {
      return;
    }

    // Dejamos terminar el cierre del modal antes
    // de actualizar la pantalla del detalle.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) {
      return;
    }

    final result = await controller.updateRequestedPets(petIds: selectedIds);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? DogGoTheme.teal : DogGoTheme.ink,
      ),
    );
  }

  Future<void> _openProposal(BuildContext context) async {
    final walk = state.walk!;

    final initialIds = walk.requestedPets.map((pet) => pet.id).toSet();

    final selectedIds = Set<int>.from(initialIds);

    final reasonController = TextEditingController();

    List<int>? submittedPetIds;
    String submittedReason = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: DogGoTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: DogGoTheme.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Proponer un cambio',
                        style: DogGoTheme.title(size: 22),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Selecciona únicamente las mascotas que puedes pasear. El dueño deberá aprobar el cambio.',
                        style: DogGoTheme.subtitle(size: 12),
                      ),
                      const SizedBox(height: 18),

                      ...walk.requestedPets.map((pet) {
                        final selected = selectedIds.contains(pet.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _SelectablePet(
                            pet: pet,
                            baseUrl: state.baseUrl,
                            selected: selected,
                            onTap: () {
                              setSheetState(() {
                                if (selected) {
                                  selectedIds.remove(pet.id);
                                } else {
                                  selectedIds.add(pet.id);
                                }
                              });
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        maxLength: 300,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Motivo del cambio',
                          hintText:
                              'Ej. Por seguridad solamente puedo llevar dos perros grandes.',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: DogGoTheme.orangeLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: DogGoTheme.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                selectedIds.length == initialIds.length
                                    ? 'Quita al menos una mascota para hacer una contrapropuesta.'
                                    : 'Propones pasear ${selectedIds.length} de ${initialIds.length} mascotas.',
                                style: DogGoTheme.caption(
                                  size: 10.5,
                                  color: DogGoTheme.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed:
                            selectedIds.isEmpty ||
                                selectedIds.length == initialIds.length
                            ? null
                            : () {
                                final reason = reasonController.text.trim();

                                if (reason.length < 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Explica brevemente por qué propones el cambio.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                submittedPetIds = selectedIds.toList();

                                submittedReason = reason;

                                // Primero cerramos la hoja.
                                // La llamada al backend se hace
                                // después de terminar la animación.
                                Navigator.pop(context);
                              },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Enviar propuesta'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));

    reasonController.dispose();

    if (!context.mounted || submittedPetIds == null) {
      return;
    }

    final result = await controller.proposePetChange(
      acceptedPetIds: submittedPetIds!,
      reason: submittedReason,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  Future<void> _respond(BuildContext context, {required bool accept}) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(accept ? 'Aceptar propuesta' : 'Rechazar propuesta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accept
                    ? 'El paseo quedarÃ¡ confirmado con las mascotas propuestas y el nuevo precio.'
                    : 'El paseo volverÃ¡ a quedar pendiente para que puedas editarlo o acordar otra opciÃ³n.',
              ),
              if (!accept) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo opcional',
                    hintText: 'Explica por quÃ© no aceptas el cambio.',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(accept ? 'Aceptar cambio' : 'Rechazar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      reasonController.dispose();
      return;
    }

    final result = await controller.respondPetChange(
      accept: accept,
      reason: reasonController.text,
    );

    reasonController.dispose();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }
}

class _WalkPetRow extends StatelessWidget {
  final WalkPet pet;
  final String? baseUrl;
  final bool proposalPending;
  final VoidCallback? onViewProfile;

  const _WalkPetRow({
    required this.pet,
    required this.baseUrl,
    required this.proposalPending,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final included = !proposalPending || pet.includedInProposal;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: included ? 1 : .52,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: included ? DogGoTheme.cream : DogGoTheme.redLight,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: included
                ? DogGoTheme.border
                : DogGoTheme.red.withValues(alpha: .25),
          ),
        ),
        child: Row(
          children: [
            _PetPhoto(pet: pet, baseUrl: baseUrl),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(size: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pet.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(size: 9.5),
                  ),
                ],
              ),
            ),
            if (proposalPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: included ? DogGoTheme.greenLight : DogGoTheme.redLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  included ? 'Incluida' : 'No incluida',
                  style: DogGoTheme.caption(
                    size: 8.5,
                    color: included ? DogGoTheme.green : DogGoTheme.red,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
            if (onViewProfile != null)
              IconButton(
                tooltip: 'Ver perfil de ${pet.name}',
                onPressed: onViewProfile,
                icon: const Icon(Icons.chevron_right_rounded),
                color: DogGoTheme.teal,
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectablePet extends StatelessWidget {
  final WalkPet pet;
  final String? baseUrl;
  final bool selected;
  final VoidCallback onTap;

  const _SelectablePet({
    required this.pet,
    required this.baseUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DogGoTheme.tealLight : DogGoTheme.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? DogGoTheme.teal : DogGoTheme.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _PetPhoto(pet: pet, baseUrl: baseUrl),
              const SizedBox(width: 11),
              Expanded(
                child: Text(pet.name, style: DogGoTheme.title(size: 14)),
              ),
              Container(
                width: 28,
                height: 28,
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
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetPhoto extends StatelessWidget {
  final WalkPet pet;
  final String? baseUrl;

  const _PetPhoto({required this.pet, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final url = pet.publicPhotoUrl(baseUrl);

    return Container(
      width: 48,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return _PetInitials(text: pet.initials);
              },
            )
          : _PetInitials(text: pet.initials),
    );
  }
}

class _PetInitials extends StatelessWidget {
  final String text;

  const _PetInitials({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: DogGoTheme.title(size: 14, color: DogGoTheme.teal),
      ),
    );
  }
}

class _ProposalSummary extends StatelessWidget {
  final WalkDetailState state;

  const _ProposalSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final walk = state.walk!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync_alt_rounded,
                color: DogGoTheme.orange,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Contrapropuesta',
                style: DogGoTheme.title(size: 14, color: DogGoTheme.ink),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            walk.petChangeReason ??
                'El paseador propuso modificar las mascotas.',
            style: DogGoTheme.body(size: 11.5, color: DogGoTheme.ink),
          ),
          const SizedBox(height: 9),
          Text(
            '${walk.proposedPetCount} de '
            '${walk.requestedPetCount} mascotas Â· '
            '${walk.proposedPriceLabel}',
            style: DogGoTheme.label(size: 10.5, color: DogGoTheme.orange),
          ),
        ],
      ),
    );
  }
}

class _PriceInformation extends StatelessWidget {
  final WalkDetailState state;

  const _PriceInformation({required this.state});

  @override
  Widget build(BuildContext context) {
    final walk = state.walk!;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: DogGoTheme.cream,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: DogGoTheme.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              walk.hasPendingPetProposal
                  ? 'Nuevo total propuesto'
                  : 'Total del paseo',
              style: DogGoTheme.body(size: 11, weight: FontWeight.w700),
            ),
          ),
          Text(
            walk.hasPendingPetProposal
                ? walk.proposedPriceLabel
                : walk.priceLabel,
            style: DogGoTheme.title(size: 17, color: DogGoTheme.teal),
          ),
        ],
      ),
    );
  }
}
