import 'package:flutter/material.dart';

import '../services/public_owner_service.dart';
import '../services/storage_service.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_theme.dart';

class PublicOwnerProfileScreen extends StatefulWidget {
  final int ownerId;
  const PublicOwnerProfileScreen({super.key, required this.ownerId});

  @override
  State<PublicOwnerProfileScreen> createState() =>
      _PublicOwnerProfileScreenState();
}

class _PublicOwnerProfileScreenState extends State<PublicOwnerProfileScreen> {
  Map<String, dynamic>? _profile;
  String? _baseUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final values = await Future.wait([
        PublicOwnerService.getProfile(widget.ownerId),
        StorageService.obtenerBaseUrl(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = values[0] as Map<String, dynamic>;
        _baseUrl = values[1] as String?;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _clean(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Perfil del dueño',
      body: _profile == null && _error == null
          ? const DogGoLoadingView(message: 'Cargando perfil...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: DogGoErrorView(message: _error!, onRetry: _load),
            )
          : _content(),
    );
  }

  Widget _content() {
    final data = _profile!;
    final name = (data['nombreCompleto'] ?? 'Dueño DogGo').toString();
    final location = [
      data['municipio'],
      data['estado'],
    ].where((value) => value?.toString().trim().isNotEmpty == true).join(', ');
    final shared = data['paseosCompartidos'] is num
        ? (data['paseosCompartidos'] as num).toInt()
        : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DogGoTheme.teal, DogGoTheme.tealDark],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 82,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: DogGoNetworkImage(
                  url: _url(data['fotoUrl']),
                  semanticLabel: 'Fotografía de $name',
                  fallback: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: DogGoTheme.title(size: 23, color: Colors.white),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        location,
                        style: DogGoTheme.body(
                          size: 11.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      shared == 1
                          ? '1 paseo realizado contigo'
                          : '$shared paseos realizados contigo',
                      style: DogGoTheme.caption(size: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          Icons.person_outline_rounded,
          'Sobre $name',
          data['descripcion']?.toString(),
          'Este dueño todavía no agregó una presentación.',
        ),
        const SizedBox(height: 12),
        _card(
          Icons.pets_outlined,
          'Preferencias de paseo',
          data['preferenciasPaseo']?.toString(),
          'Las indicaciones específicas aparecen en cada paseo.',
        ),
        const SizedBox(height: 16),
        Text(
          'Por privacidad, DogGo no comparte aquí domicilio, teléfono ni correo. Los datos necesarios para el servicio permanecen dentro del paseo.',
          style: DogGoTheme.caption(size: 10.5),
        ),
      ],
    );
  }

  Widget _card(IconData icon, String title, String? value, String fallback) {
    final text = value?.trim().isNotEmpty == true ? value!.trim() : fallback;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DogGoTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DogGoTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DogGoTheme.title(size: 16)),
                const SizedBox(height: 6),
                Text(text, style: DogGoTheme.subtitle(size: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _url(dynamic path) {
    final value = path?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http')) return value;
    final base = _baseUrl?.replaceAll(RegExp(r'/+$'), '') ?? '';
    return base.isEmpty
        ? value
        : '$base/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String _clean(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiException: ', '')
      .trim();
}
