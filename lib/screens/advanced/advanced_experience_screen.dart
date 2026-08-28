import 'package:flutter/material.dart';

import '../../services/advanced_experience_service.dart';
import '../../services/session_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import 'family_screen.dart';
import 'matching_screen.dart';
import 'pet_wellness_screen.dart';
import 'planning_hub_screen.dart';

class AdvancedExperienceScreen extends StatefulWidget {
  const AdvancedExperienceScreen({super.key});

  @override
  State<AdvancedExperienceScreen> createState() =>
      _AdvancedExperienceScreenState();
}

class _AdvancedExperienceScreenState extends State<AdvancedExperienceScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const {};
  String _role = '';

  bool get _isWalker => SessionService.esPaseadorRol(_role);

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
        AdvancedExperienceService.summary(),
        SessionService.obtenerRol(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = Map<String, dynamic>.from(values[0] as Map);
        _role = values[1]?.toString() ?? '';
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

  Future<void> _open(Widget screen) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'DogGo 360',
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const DogGoLoadingView(message: 'Preparando tu experiencia...')
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
                  _Hero(summary: _summary, isWalker: _isWalker),
                  const SizedBox(height: 22),
                  Text(
                    'Todo alrededor del paseo',
                    style: DogGoTheme.title(size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isWalker
                        ? 'Organiza tus llegadas, acuerdos y reputación desde un solo lugar.'
                        : 'Planea, cuida y comparte la vida de tus perros desde un solo lugar.',
                    style: DogGoTheme.subtitle(size: 13.5),
                  ),
                  const SizedBox(height: 16),
                  _ModuleCard(
                    icon: Icons.event_repeat_rounded,
                    color: DogGoTheme.teal,
                    title: 'Planificación avanzada',
                    subtitle:
                        'Paseos semanales, calendario, repetir, preparación y reprogramación.',
                    onTap: () => _open(PlanningHubScreen(role: _role)),
                  ),
                  if (!_isWalker) ...[
                    const SizedBox(height: 12),
                    _ModuleCard(
                      icon: Icons.auto_awesome_rounded,
                      color: DogGoTheme.orange,
                      title: 'Matching y confianza',
                      subtitle:
                          'Recomendaciones explicadas, favorito, suplente e insignias reales.',
                      onTap: () => _open(const MatchingScreen()),
                    ),
                    const SizedBox(height: 12),
                    _ModuleCard(
                      icon: Icons.health_and_safety_rounded,
                      color: DogGoTheme.green,
                      title: 'Salud, cuidados y recuerdos',
                      subtitle:
                          'Indicaciones, contactos, logros, estadísticas y fotografías de cada perro.',
                      onTap: () => _open(const PetWellnessScreen()),
                    ),
                    const SizedBox(height: 12),
                    _ModuleCard(
                      icon: Icons.family_restroom_rounded,
                      color: DogGoTheme.purple,
                      title: 'Familia DogGo',
                      subtitle:
                          'Comparte mascotas y asigna permisos de cuidado a personas de confianza.',
                      onTap: () => _open(const FamilyScreen()),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  static String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _Hero extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool isWalker;

  const _Hero({required this.summary, required this.isWalker});

  @override
  Widget build(BuildContext context) {
    final first = isWalker
        ? summary['calificacion'] ?? 0
        : summary['mascotas'] ?? 0;
    final firstLabel = isWalker ? 'calificación' : 'mascotas';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DogGoTheme.teal, DogGoTheme.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: DogGoTheme.elevatedShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'VIDA DOGGO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isWalker
                ? 'Tu operación, mejor coordinada'
                : 'Todo su mundo, conectado',
            style: DogGoTheme.title(size: 25, color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            isWalker
                ? 'Más claridad antes, durante y después de cada paseo.'
                : 'Planeación, confianza y cuidados que acompañan cada paseo.',
            style: DogGoTheme.body(
              size: 13.5,
              color: Colors.white.withValues(alpha: .82),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _Metric(value: '$first', label: firstLabel),
              _Metric(value: '${summary['proximos'] ?? 0}', label: 'próximos'),
              _Metric(
                value: '${summary['completados'] ?? 0}',
                label: 'completados',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: DogGoTheme.title(size: 22, color: Colors.white)),
        Text(
          label,
          style: DogGoTheme.caption(color: Colors.white.withValues(alpha: .72)),
        ),
      ],
    ),
  );
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: DogGoTheme.card,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: DogGoTheme.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DogGoTheme.title(size: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: DogGoTheme.subtitle(size: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: DogGoTheme.muted),
          ],
        ),
      ),
    ),
  );
}
