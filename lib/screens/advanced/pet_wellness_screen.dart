import 'package:flutter/material.dart';

import '../../services/advanced_experience_service.dart';
import '../../services/perros_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_network_image.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../shared/widgets/doggo_section_card.dart';
import '../../theme/doggo_theme.dart';
import '../pets/models/pet.dart';

class PetWellnessScreen extends StatefulWidget {
  final int? initialPetId;
  final List<Map<String, dynamic>> additionalPets;
  const PetWellnessScreen({
    super.key,
    this.initialPetId,
    this.additionalPets = const [],
  });

  @override
  State<PetWellnessScreen> createState() => _PetWellnessScreenState();
}

class _PetWellnessScreenState extends State<PetWellnessScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final Map<String, TextEditingController> _fields = {
    for (final key in const [
      'alimentacion',
      'medicamentos',
      'alergias',
      'indicacionesCorrea',
      'indicacionesConducta',
      'contactoEmergenciaNombre',
      'contactoEmergenciaTelefono',
      'veterinarioNombre',
      'veterinarioTelefono',
      'notasEspeciales',
    ])
      key: TextEditingController(),
  };
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Pet> _pets = const [];
  int? _selectedId;
  Map<String, dynamic> _achievements = const {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadPets();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await PerrosService.obtenerMisPerros();
      if (response['success'] != true) {
        throw Exception(
          response['message'] ?? 'No se pudieron cargar tus mascotas.',
        );
      }
      final pets = Pet.listFrom(response['data']).toList();
      for (final shared in widget.additionalPets) {
        final pet = Pet.fromMap(shared);
        if (pet.hasValidId && !pets.any((item) => item.id == pet.id)) {
          pets.add(pet);
        }
      }
      final selected = pets.any((pet) => pet.id == widget.initialPetId)
          ? widget.initialPetId
          : pets.firstOrNull?.id;
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _selectedId = selected;
      });
      if (selected != null) await _loadPet(selected);
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _loadPet(int id) async {
    setState(() {
      _selectedId = id;
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        AdvancedExperienceService.petCare(id),
        AdvancedExperienceService.petAchievements(id),
      ]);
      final care = values[0];
      for (final entry in _fields.entries) {
        entry.value.text = care[entry.key]?.toString() ?? '';
      }
      if (!mounted) return;
      setState(() {
        _achievements = values[1];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _clean(error);
      });
    }
  }

  Future<void> _save() async {
    final id = _selectedId;
    if (id == null) return;
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.savePetCare(id, {
        for (final entry in _fields.entries) entry.key: entry.value.text.trim(),
      });
      if (mounted) _message('Plan de cuidados guardado.');
      await _loadPet(id);
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Pet? get _selectedPet =>
      _pets.where((pet) => pet.id == _selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Salud y vida de tu perro',
      body: _error != null && _pets.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _loadPets),
            )
          : Column(
              children: [
                if (_pets.isNotEmpty)
                  _PetSelector(
                    pets: _pets,
                    selectedId: _selectedId,
                    onSelected: _loading ? null : _loadPet,
                  ),
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.health_and_safety_outlined),
                      text: 'Cuidados',
                    ),
                    Tab(
                      icon: Icon(Icons.emoji_events_outlined),
                      text: 'Logros',
                    ),
                  ],
                ),
                Expanded(
                  child: _loading
                      ? const DogGoLoadingView(message: 'Cargando su mundo...')
                      : _pets.isEmpty
                      ? const _NoPets()
                      : TabBarView(
                          controller: _tabs,
                          children: [_careTab(), _achievementsTab()],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _careTab() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
    children: [
      DogGoSectionCard(
        title: 'Rutina diaria',
        subtitle: 'Lo que el paseador debe saber antes de salir.',
        icon: Icons.restaurant_rounded,
        child: Column(
          children: [
            _field(
              'alimentacion',
              'Alimentación',
              'Horarios, porciones o premios permitidos',
            ),
            _field('medicamentos', 'Medicinas', 'Nombre, dosis y horario'),
            _field(
              'alergias',
              'Alergias',
              'Alimentos, plantas o sustancias a evitar',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      DogGoSectionCard(
        title: 'Paseo y comportamiento',
        subtitle: 'Instrucciones prácticas y señales de conducta.',
        icon: Icons.pets_rounded,
        child: Column(
          children: [
            _field(
              'indicacionesCorrea',
              'Correa y arnés',
              'Cuál usar y cómo colocarlo',
            ),
            _field(
              'indicacionesConducta',
              'Comportamiento',
              'Reactividad, miedos, comandos y límites',
            ),
            _field(
              'notasEspeciales',
              'Notas especiales',
              'Cualquier otro detalle importante',
              maxLines: 4,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      DogGoSectionCard(
        title: 'Contactos de respaldo',
        subtitle: 'Personas y clínica a quienes llamar si ocurre algo.',
        icon: Icons.emergency_rounded,
        child: Column(
          children: [
            _field(
              'contactoEmergenciaNombre',
              'Contacto de emergencia',
              'Nombre completo',
            ),
            _field(
              'contactoEmergenciaTelefono',
              'Teléfono de emergencia',
              'Número de contacto',
              type: TextInputType.phone,
            ),
            _field('veterinarioNombre', 'Veterinario o clínica', 'Nombre'),
            _field(
              'veterinarioTelefono',
              'Teléfono veterinario',
              'Número de la clínica',
              type: TextInputType.phone,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Guardando...' : 'Guardar plan de cuidados'),
      ),
    ],
  );

  Widget _field(
    String key,
    String label,
    String hint, {
    int maxLines = 2,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _fields[key],
      maxLines: maxLines,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  Widget _achievementsTab() {
    final achievements = _achievements['logros'] is List
        ? _achievements['logros'] as List
        : const [];
    final memories = _achievements['recuerdos'] is List
        ? _achievements['recuerdos'] as List
        : const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DogGoTheme.orange, Color(0xFFF2BE59)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_achievements['nombre'] ?? _selectedPet?.name ?? 'Tu perro'}',
                      style: DogGoTheme.title(size: 21, color: Colors.white),
                    ),
                    Text(
                      '${_achievements['paseos'] ?? 0} paseos · ${_achievements['minutos'] ?? 0} minutos de aventura',
                      style: DogGoTheme.body(size: 12.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Logros', style: DogGoTheme.title(size: 20)),
        const SizedBox(height: 10),
        ...achievements.whereType<Map>().map((raw) {
          final item = Map<String, dynamic>.from(raw);
          final progress = int.tryParse('${item['progreso'] ?? 0}') ?? 0;
          final goal = int.tryParse('${item['meta'] ?? 1}') ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item['desbloqueado'] == true
                      ? DogGoTheme.greenLight
                      : DogGoTheme.purpleLight,
                  child: Icon(
                    item['desbloqueado'] == true
                        ? Icons.verified_rounded
                        : Icons.lock_outline_rounded,
                    color: item['desbloqueado'] == true
                        ? DogGoTheme.green
                        : DogGoTheme.purple,
                  ),
                ),
                title: Text(
                  '${item['nombre']}',
                  style: DogGoTheme.body(weight: FontWeight.w800),
                ),
                subtitle: LinearProgressIndicator(
                  value: goal <= 0 ? 0 : (progress / goal).clamp(0, 1),
                ),
                trailing: Text('$progress/$goal'),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text('Recuerdos del paseo', style: DogGoTheme.title(size: 20)),
        const SizedBox(height: 10),
        if (memories.isEmpty)
          const Text(
            'Las fotografías registradas durante los paseos aparecerán aquí.',
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: memories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, index) {
            final item = memories[index] is Map
                ? Map<String, dynamic>.from(memories[index] as Map)
                : const <String, dynamic>{};
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DogGoNetworkImage(
                url: item['fotoUrl']?.toString(),
                semanticLabel:
                    item['descripcion']?.toString() ?? 'Recuerdo de paseo',
                fit: BoxFit.cover,
                fallback: const ColoredBox(
                  color: DogGoTheme.tealLight,
                  child: Icon(Icons.photo_outlined),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _PetSelector extends StatelessWidget {
  final List<Pet> pets;
  final int? selectedId;
  final ValueChanged<int>? onSelected;
  const _PetSelector({
    required this.pets,
    required this.selectedId,
    this.onSelected,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 92,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      scrollDirection: Axis.horizontal,
      itemCount: pets.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, index) {
        final pet = pets[index];
        return ChoiceChip(
          selected: pet.id == selectedId,
          onSelected: onSelected == null ? null : (_) => onSelected!(pet.id),
          avatar: CircleAvatar(
            backgroundColor: DogGoTheme.tealLight,
            child: DogGoNetworkImage(
              url: pet.photoPath,
              semanticLabel: 'Foto de ${pet.name}',
              fallback: const Icon(Icons.pets_rounded, size: 17),
            ),
          ),
          label: Text(pet.name),
        );
      },
    ),
  );
}

class _NoPets extends StatelessWidget {
  const _NoPets();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text(
        'Registra una mascota para crear su centro de salud y recuerdos.',
      ),
    ),
  );
}
