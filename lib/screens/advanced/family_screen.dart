import 'package:flutter/material.dart';

import '../../services/advanced_experience_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import 'pet_wellness_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final _name = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _family = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AdvancedExperienceService.family();
      if (!mounted) return;
      setState(() {
        _family = data;
        _name.text = data['nombre']?.toString() ?? 'Mi familia DogGo';
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

  Future<void> _saveName() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.saveFamily(_name.text);
      if (mounted) _message('Familia guardada.');
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addMember() async {
    final result = await showDialog<_MemberDraft>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (result == null) return;
    setState(() => _saving = true);
    try {
      await AdvancedExperienceService.addFamilyMember(
        email: result.email,
        canRequestWalks: false,
        canEditCare: result.canEdit,
      );
      if (mounted) _message('Persona agregada a tu familia DogGo.');
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar de la familia'),
        content: Text(
          '$name dejará de tener acceso a las mascotas compartidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdvancedExperienceService.removeFamilyMember(id);
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    }
  }

  Future<void> _openPet(Map<String, dynamic> pet) async {
    final id = int.tryParse('${pet['id'] ?? ''}');
    if (id == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            PetWellnessScreen(initialPetId: id, additionalPets: [pet]),
      ),
    );
  }

  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salir de la familia'),
        content: const Text(
          'Dejarás de ver sus mascotas y sus planes de cuidados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdvancedExperienceService.leaveFamily();
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage =
        _family['configurada'] != true || _family['esPropietario'] == true;
    return DogGoScreenScaffold(
      title: 'Familia DogGo',
      body: _loading
          ? const DogGoLoadingView(message: 'Cargando familia...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [DogGoTheme.purple, Color(0xFF777F9E)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.family_restroom_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _family['configurada'] == true
                                  ? '${_family['nombre']}'
                                  : 'Crea tu círculo de cuidado',
                              style: DogGoTheme.title(
                                size: 21,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Varias personas, las mismas mascotas y permisos claros.',
                              style: DogGoTheme.body(
                                size: 12.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (canManage)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la familia',
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _saving ? null : _saveName,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Guardar familia'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: DogGoTheme.purple,
                      ),
                      title: Text('${_family['nombre'] ?? 'Familia DogGo'}'),
                      subtitle: Text(
                        'Administrada por ${_family['propietario'] ?? 'su propietario'}.',
                      ),
                    ),
                  ),
                if (_family['configurada'] == true) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Personas con acceso',
                          style: DogGoTheme.title(size: 19),
                        ),
                      ),
                      if (_family['esPropietario'] == true)
                        FilledButton.tonalIcon(
                          onPressed: _saving ? null : _addMember,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Agregar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._members().map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: DogGoTheme.purpleLight,
                            child: Icon(
                              Icons.person_rounded,
                              color: DogGoTheme.purple,
                            ),
                          ),
                          title: Text(
                            '${member['nombre'] ?? 'Miembro'}',
                            style: DogGoTheme.body(weight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            _permissions(member),
                            style: DogGoTheme.subtitle(size: 12),
                          ),
                          trailing: _family['esPropietario'] == true
                              ? IconButton(
                                  tooltip: 'Quitar acceso',
                                  onPressed: () => _remove(
                                    int.tryParse('${member['id']}') ?? 0,
                                    '${member['nombre'] ?? 'Esta persona'}',
                                  ),
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: DogGoTheme.red,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  if (_members().isEmpty)
                    const Text(
                      'Agrega a alguien con cuenta DogGo usando su correo.',
                    ),
                  const SizedBox(height: 22),
                  Text(
                    'Mascotas compartidas',
                    style: DogGoTheme.title(size: 19),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pets()
                        .map(
                          (pet) => ActionChip(
                            avatar: const Icon(Icons.pets_rounded, size: 17),
                            label: Text('${pet['nombre'] ?? 'Mascota'}'),
                            onPressed: () => _openPet(pet),
                          ),
                        )
                        .toList(),
                  ),
                  if (_family['esPropietario'] != true) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _leaveFamily,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Salir de esta familia'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _members() => _family['miembros'] is List
      ? (_family['miembros'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
      : const [];
  List<Map<String, dynamic>> _pets() => _family['mascotas'] is List
      ? (_family['mascotas'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
      : const [];
  String _permissions(Map<String, dynamic> member) {
    final values = <String>['Puede ver'];
    if (member['puedeEditarCuidados'] == true) values.add('editar cuidados');
    return values.join(' · ');
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _MemberDraft {
  final String email;
  final bool canEdit;
  const _MemberDraft(this.email, this.canEdit);
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();
  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _email = TextEditingController();
  bool _edit = false;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Agregar cuidador'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo de su cuenta DogGo',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _edit,
            onChanged: (v) => setState(() => _edit = v),
            title: const Text('Puede editar cuidados'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final email = _email.text.trim();
          if (email.isEmpty) return;
          Navigator.pop(context, _MemberDraft(email, _edit));
        },
        child: const Text('Agregar'),
      ),
    ],
  );
}
