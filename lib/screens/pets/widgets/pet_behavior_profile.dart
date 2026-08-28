import 'package:flutter/material.dart';

import '../../../shared/widgets/doggo_network_image.dart';
import '../../../theme/doggo_radius.dart';
import '../../../theme/doggo_spacing.dart';
import '../../../theme/doggo_theme.dart';
import '../../walks/models/walk_pet.dart';

class PetBehaviorProfile extends StatelessWidget {
  final WalkPet pet;
  final String? baseUrl;

  const PetBehaviorProfile({
    super.key,
    required this.pet,
    required this.baseUrl,
  });

  static Future<void> show(
    BuildContext context, {
    required WalkPet pet,
    required String? baseUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .9,
        child: PetBehaviorProfile(pet: pet, baseUrl: baseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = pet.publicPhotoUrl(baseUrl);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DogGoSpacing.screenHorizontal,
        4,
        DogGoSpacing.screenHorizontal,
        32,
      ),
      children: [
        Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 72,
                height: 72,
                child: DogGoNetworkImage(
                  url: photo,
                  semanticLabel: 'Fotografía de ${pet.name}',
                  fallback: ColoredBox(
                    color: DogGoTheme.tealLight,
                    child: Center(
                      child: Text(
                        pet.initials,
                        style: DogGoTheme.title(color: DogGoTheme.teal),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: DogGoTheme.title(size: 24)),
                  const SizedBox(height: 3),
                  Text(pet.description, style: DogGoTheme.subtitle(size: 12.5)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cerrar perfil',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ProfileCard(
          title: 'Datos generales',
          icon: Icons.pets_outlined,
          children: [
            _ProfileRow('Tamaño', pet.size),
            _ProfileRow(
              'Peso',
              pet.weight == null
                  ? 'Sin registrar'
                  : '${pet.weight!.toStringAsFixed(1)} kg',
            ),
            _ProfileRow('Sexo', pet.sex ?? 'Sin registrar'),
            _ProfileRow('Esterilizado', _yesNo(pet.sterilized)),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileCard(
          title: 'Personalidad y convivencia',
          icon: Icons.psychology_alt_outlined,
          children: [
            _ProfileRow('Temperamento', pet.temperament ?? 'Sin registrar'),
            _ProfileRow('Nivel de energía', pet.energyLevel ?? 'Sin registrar'),
            _ProfileRow('Con otros perros', _yesNo(pet.socialWithDogs)),
            _ProfileRow('Con personas', _yesNo(pet.socialWithPeople)),
            _ProfileRow('Con niños', _yesNo(pet.socialWithChildren)),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileCard(
          title: 'Indicaciones para el paseo',
          icon: Icons.shield_outlined,
          alert: pet.reactive == true || pet.escapeRisk == true,
          children: [
            _ProfileRow('Con correa', pet.leashBehavior ?? 'Sin registrar'),
            _ProfileRow('Reactivo', _yesNo(pet.reactive)),
            _ProfileRow('Riesgo de escape', _yesNo(pet.escapeRisk)),
            _ProfileRow(
              'Miedos o detonantes',
              pet.fearsTriggers ?? 'Sin registrar',
            ),
            _ProfileRow(
              'Comandos conocidos',
              pet.knownCommands ?? 'Sin registrar',
            ),
          ],
        ),
        if (pet.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _ProfileCard(
            title: 'Notas y cuidados',
            icon: Icons.notes_outlined,
            children: [_ProfileRow('Indicaciones', pet.notes)],
          ),
        ],
      ],
    );
  }

  static String _yesNo(bool? value) => value == null
      ? 'Sin registrar'
      : value
      ? 'Sí'
      : 'No';
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool alert;

  const _ProfileCard({
    required this.title,
    required this.icon,
    required this.children,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: alert ? DogGoTheme.orangeLight : DogGoTheme.card,
      borderRadius: BorderRadius.circular(DogGoRadius.large),
      border: Border.all(
        color: alert
            ? DogGoTheme.orange.withValues(alpha: .35)
            : DogGoTheme.border,
      ),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, color: alert ? DogGoTheme.orange : DogGoTheme.teal),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: DogGoTheme.title(size: 16))),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: DogGoTheme.subtitle(size: 11.5))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DogGoTheme.body(size: 12.5, weight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
