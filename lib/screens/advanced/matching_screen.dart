import 'package:flutter/material.dart';

import '../../services/advanced_experience_service.dart';
import '../../services/app_preferences_service.dart';
import '../../services/storage_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_network_image.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import '../detalle_paseador_screen.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _walkers = const [];
  String? _baseUrl;
  final Set<int> _updating = {};

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
      final values = await Future.wait<dynamic>([
        AdvancedExperienceService.matching(),
        StorageService.obtenerBaseUrl(),
      ]);
      final walkers = (values[0] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      await AppPreferencesService.replaceFavoriteWalkerIds(
        walkers
            .where((item) => item['esFavorito'] == true)
            .map((item) => int.tryParse('${item['id']}') ?? 0),
      );
      if (!mounted) return;
      setState(() {
        _walkers = walkers;
        _baseUrl = values[1]?.toString();
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

  Future<void> _preference(
    Map<String, dynamic> walker, {
    bool? favorite,
    bool? backup,
  }) async {
    final id = _id(walker);
    if (id == null || _updating.contains(id)) return;
    setState(() => _updating.add(id));
    var favoriteValue = favorite ?? walker['esFavorito'] == true;
    var backupValue = backup ?? walker['esSuplente'] == true;
    if (favorite == true) backupValue = false;
    if (backup == true) favoriteValue = false;
    try {
      await AdvancedExperienceService.saveWalkerPreference(
        id,
        favorite: favoriteValue,
        backup: backupValue,
        priority: favoriteValue
            ? 10
            : backupValue
            ? 5
            : 0,
      );
      await AppPreferencesService.setFavoriteWalker(id, favoriteValue);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (mounted) _message(_clean(error));
    } finally {
      if (mounted) setState(() => _updating.remove(id));
    }
  }

  Future<void> _showTrust(Map<String, dynamic> walker) async {
    final id = _id(walker);
    if (id == null) return;
    try {
      final data = await AdvancedExperienceService.trust(id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TrustSheet(data: data),
      );
    } catch (error) {
      if (mounted) _message(_clean(error));
    }
  }

  Future<void> _showSlots(Map<String, dynamic> walker) async {
    final id = _id(walker);
    if (id == null) return;
    try {
      final data = await AdvancedExperienceService.recommendations(
        walkerId: id,
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _SlotsSheet(data: data),
      );
    } catch (error) {
      if (mounted) _message(_clean(error));
    }
  }

  Future<void> _open(Map<String, dynamic> walker) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => DetallePaseadorScreen(paseador: walker),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Matching inteligente',
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const DogGoLoadingView(message: 'Buscando el mejor match...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: DogGoTheme.orangeLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: DogGoTheme.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'El orden combina verificación, reputación, experiencia, cercanía y tu historial real.',
                            style: DogGoTheme.body(
                              size: 13,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_walkers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hay paseadores aprobados disponibles en este momento.',
                        ),
                      ),
                    ),
                  ..._walkers.map(
                    (walker) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WalkerMatchCard(
                        walker: walker,
                        baseUrl: _baseUrl,
                        updating: _updating.contains(_id(walker)),
                        onOpen: () => _open(walker),
                        onTrust: () => _showTrust(walker),
                        onSlots: () => _showSlots(walker),
                        onFavorite: () => _preference(
                          walker,
                          favorite: walker['esFavorito'] != true,
                        ),
                        onBackup: () => _preference(
                          walker,
                          backup: walker['esSuplente'] != true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int? _id(Map<String, dynamic> value) => int.tryParse('${value['id'] ?? ''}');
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _WalkerMatchCard extends StatelessWidget {
  final Map<String, dynamic> walker;
  final String? baseUrl;
  final bool updating;
  final VoidCallback onOpen;
  final VoidCallback onTrust;
  final VoidCallback onSlots;
  final VoidCallback onFavorite;
  final VoidCallback onBackup;
  const _WalkerMatchCard({
    required this.walker,
    required this.baseUrl,
    required this.updating,
    required this.onOpen,
    required this.onTrust,
    required this.onSlots,
    required this.onFavorite,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = walker['razones'] is List
        ? (walker['razones'] as List).map((e) => '$e').toList()
        : <String>[];
    final score = double.tryParse('${walker['score'] ?? 0}') ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 58,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: DogGoNetworkImage(
                      url: _photoUrl(walker['fotoUrl']?.toString()),
                      semanticLabel: 'Foto de ${walker['nombre']}',
                      fallback: const ColoredBox(
                        color: DogGoTheme.tealLight,
                        child: Icon(
                          Icons.person_rounded,
                          color: DogGoTheme.teal,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${walker['nombre'] ?? 'Paseador'}',
                        style: DogGoTheme.title(size: 17),
                      ),
                      Text(
                        '★ ${walker['calificacionPromedio'] ?? 0} · \$${walker['tarifaPorHora'] ?? 0}/h',
                        style: DogGoTheme.subtitle(size: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DogGoTheme.greenLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(0)}%',
                    style: DogGoTheme.caption(
                      color: DogGoTheme.green,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reasons
                  .take(4)
                  .map(
                    (reason) => Chip(
                      label: Text(reason),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: walker['esFavorito'] == true,
                  onSelected: updating ? null : (_) => onFavorite(),
                  avatar: const Icon(Icons.favorite_rounded, size: 17),
                  label: const Text('Favorito'),
                ),
                FilterChip(
                  selected: walker['esSuplente'] == true,
                  onSelected: updating ? null : (_) => onBackup(),
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 17),
                  label: const Text('Suplente'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 17),
                  label: const Text('Confianza'),
                  onPressed: onTrust,
                ),
                ActionChip(
                  avatar: const Icon(Icons.schedule_rounded, size: 17),
                  label: const Text('Horarios'),
                  onPressed: onSlots,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onOpen,
                child: const Text('Ver perfil y solicitar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _photoUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final server = baseUrl?.trim();
    if (server == null || server.isEmpty) return value;
    return '${server.replaceFirst(RegExp(r'/+$'), '')}/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

class _TrustSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TrustSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final badges = data['insignias'] is List
        ? data['insignias'] as List
        : const [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
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
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Confianza de ${data['nombre'] ?? 'paseador'}',
              style: DogGoTheme.title(size: 21),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TrustMetric(
                  value: '${data['score'] ?? 0}%',
                  label: 'confianza',
                ),
                _TrustMetric(
                  value: '${data['finalizados'] ?? 0}',
                  label: 'paseos',
                ),
                _TrustMetric(
                  value: '${data['clientesRecurrentes'] ?? 0}',
                  label: 'clientes fieles',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: badges
                  .map(
                    (e) => Chip(
                      avatar: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 17,
                      ),
                      label: Text('$e'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'La puntuación usa verificación, calificaciones, experiencia, paseos terminados y señales operativas.',
              style: DogGoTheme.subtitle(size: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  final String value;
  final String label;
  const _TrustMetric({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: DogGoTheme.title(size: 20, color: DogGoTheme.teal)),
        Text(label, textAlign: TextAlign.center, style: DogGoTheme.caption()),
      ],
    ),
  );
}

class _SlotsSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SlotsSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final slots = data['horarios'] is List
        ? data['horarios'] as List
        : const [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horarios recomendados', style: DogGoTheme.title(size: 21)),
            const SizedBox(height: 6),
            Text(
              'Estimado: \$${data['precioTotal'] ?? 0} · ${data['duracionMinutos'] ?? 60} min',
              style: DogGoTheme.body(
                color: DogGoTheme.teal,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (slots.isEmpty)
              const Text(
                'No encontramos espacios próximos para esta duración.',
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((raw) {
                final date = DateTime.tryParse('$raw')?.toLocal();
                return Chip(
                  avatar: const Icon(Icons.schedule_rounded, size: 17),
                  label: Text(
                    date == null
                        ? '$raw'
                        : '${date.day}/${date.month} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
