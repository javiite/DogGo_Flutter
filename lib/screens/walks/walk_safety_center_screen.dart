import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/walk_experience_service.dart';
import '../../shared/widgets/doggo_error_view.dart';
import '../../shared/widgets/doggo_loading_view.dart';
import '../../shared/widgets/doggo_network_image.dart';
import '../../shared/widgets/doggo_screen_scaffold.dart';
import '../../theme/doggo_theme.dart';
import 'models/walk_detail.dart';

class WalkSafetyCenterScreen extends StatefulWidget {
  final WalkDetail walk;
  final String role;
  final String? baseUrl;
  final bool canOpenChat;
  final bool canOpenMap;
  final bool canOpenTracking;
  final VoidCallback onChat;
  final VoidCallback onMap;
  final VoidCallback onTracking;

  const WalkSafetyCenterScreen({
    super.key,
    required this.walk,
    required this.role,
    required this.baseUrl,
    required this.canOpenChat,
    required this.canOpenMap,
    required this.canOpenTracking,
    required this.onChat,
    required this.onMap,
    required this.onTracking,
  });

  @override
  State<WalkSafetyCenterScreen> createState() => _WalkSafetyCenterScreenState();
}

class _WalkSafetyCenterScreenState extends State<WalkSafetyCenterScreen> {
  final _picker = ImagePicker();
  bool _loading = true;
  bool _acting = false;
  String? _error;
  Map<String, dynamic> _security = const {};
  Map<String, dynamic> _report = const {};
  List<Map<String, dynamic>> _events = const [];

  bool get _isOwner {
    final value = widget.role.toLowerCase();
    return value.contains('due') ||
        value.contains('owner') ||
        value == 'cliente';
  }

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
        WalkExperienceService.security(widget.walk.id),
        WalkExperienceService.report(widget.walk.id),
        WalkExperienceService.events(widget.walk.id),
      ]);
      if (!mounted) return;
      setState(() {
        _security = values[0] as Map<String, dynamic>;
        _report = values[1] as Map<String, dynamic>;
        _events = values[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _clean(error);
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
    } catch (error) {
      _message(_clean(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _generatePins() => _run(() async {
    final data = await WalkExperienceService.generatePins(
      widget.walk.id,
      deliveryRequiresPin: true,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('PIN de transferencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PinValue('Recogida', (data['pinRecogida'] ?? '').toString()),
            const SizedBox(height: 9),
            _PinValue('Entrega', (data['pinEntrega'] ?? '').toString()),
            const SizedBox(height: 12),
            const Text(
              'Compártelos únicamente en persona. Por seguridad no volverán a mostrarse.',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    await _load();
  });

  Future<void> _confirm(String type) => _run(() async {
    String? pin;
    if (!_isOwner) {
      pin = await _askText(
        'PIN de ${type.toLowerCase()}',
        hint: '0000',
        digits: true,
        maximum: 4,
      );
      if (pin == null || pin.length != 4) return;
    } else {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmar ${type.toLowerCase()}'),
          content: Text(
            type == 'Recogida'
                ? 'Confirma que entregaste personalmente a ${widget.walk.petsLabel}.'
                : 'Confirma que recibiste nuevamente a ${widget.walk.petsLabel}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    await WalkExperienceService.confirmTransfer(
      widget.walk.id,
      type: type,
      pin: pin,
    );
    _message('$type confirmada.', success: true);
    await _load();
  });

  Future<void> _addEvent(String type, String label) => _run(() async {
    String? description;
    if (type == 'Nota' || type == 'Incidente') {
      description = await _askText(label, hint: 'Describe lo ocurrido...');
      if (description == null) return;
    }
    await WalkExperienceService.registerEvent(
      widget.walk.id,
      type: type,
      description: description,
    );
    _message('$label registrado.', success: true);
    await _load();
  });

  Future<void> _addPhoto() => _run(() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar fotografía'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    await WalkExperienceService.uploadEventPhoto(widget.walk.id, image.path);
    _message('Foto agregada a la bitácora.', success: true);
    await _load();
  });

  Future<void> _share() => _run(() async {
    final data = await WalkExperienceService.createShareLink(widget.walk.id);
    await Clipboard.setData(
      ClipboardData(text: (data['url'] ?? '').toString()),
    );
    _message('Enlace temporal copiado. Expira automáticamente.', success: true);
    await _load();
  });

  Future<void> _revokeShare() => _run(() async {
    await WalkExperienceService.revokeShareLink(widget.walk.id);
    _message('Enlace compartido desactivado.', success: true);
    await _load();
  });

  Future<String?> _askText(
    String title, {
    required String hint,
    bool digits = false,
    int maximum = 300,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: maximum,
          maxLines: digits ? 1 : 4,
          keyboardType: digits ? TextInputType.number : TextInputType.text,
          inputFormatters: digits
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _message(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Experiencia del paseo',
      actions: [
        IconButton(
          onPressed: _loading || _acting ? null : _load,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const DogGoLoadingView(message: 'Preparando la experiencia...')
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: DogGoErrorView(
                title: 'La experiencia aún no está disponible',
                message: _error!,
                icon: Icons.route_outlined,
                onRetry: _load,
              ),
            )
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    children: [
                      _Hero(walk: widget.walk),
                      const SizedBox(height: 14),
                      _securityCard(),
                      if (widget.walk.isInProgress) ...[
                        const SizedBox(height: 14),
                        _eventComposer(),
                      ],
                      const SizedBox(height: 14),
                      _summaryCard(),
                      const SizedBox(height: 14),
                      _timelineCard(),
                      const SizedBox(height: 14),
                      _toolsCard(),
                    ],
                  ),
                ),
                if (_acting)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
    );
  }

  Widget _securityCard() {
    final pickup = _security['recogidaConfirmada'] == true;
    final delivery = _security['entregaConfirmada'] == true;
    final pins = _security['pinesGenerados'] == true;
    return _Card(
      title: 'Entrega segura',
      subtitle: 'Confirma quién recoge y quién devuelve a tu mascota.',
      icon: Icons.verified_user_outlined,
      child: Column(
        children: [
          _StatusRow('Recogida', pickup),
          const SizedBox(height: 8),
          _StatusRow('Entrega', delivery),
          const SizedBox(height: 13),
          if (_isOwner && !pickup)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _acting ? null : _generatePins,
                icon: const Icon(Icons.pin_outlined),
                label: Text(pins ? 'Generar PIN nuevo' : 'Generar PIN seguro'),
              ),
            ),
          if (!pickup)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _acting ? null : () => _confirm('Recogida'),
                icon: const Icon(Icons.pets_rounded),
                label: Text(
                  _isOwner ? 'Confirmar recogida' : 'Ingresar PIN de recogida',
                ),
              ),
            ),
          if (widget.walk.isInProgress && !delivery)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _acting ? null : () => _confirm('Entrega'),
                icon: const Icon(Icons.home_rounded),
                label: Text(
                  _isOwner ? 'Confirmar entrega' : 'Ingresar PIN de entrega',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _eventComposer() => _Card(
    title: 'Registrar ahora',
    subtitle: 'Cada momento quedará en la bitácora y el reporte final.',
    icon: Icons.add_task_rounded,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _EventAction(
          Icons.water_drop_outlined,
          'Agua',
          () => _addEvent('Agua', 'Agua'),
        ),
        _EventAction(
          Icons.grass_outlined,
          'Pipi',
          () => _addEvent('Pipi', 'Pipi'),
        ),
        _EventAction(
          Icons.eco_outlined,
          'Popó',
          () => _addEvent('Popo', 'Popó'),
        ),
        _EventAction(
          Icons.pause_circle_outline,
          'Pausa',
          () => _addEvent('Pausa', 'Pausa'),
        ),
        _EventAction(
          Icons.sports_tennis_outlined,
          'Juego',
          () => _addEvent('Juego', 'Juego'),
        ),
        _EventAction(
          Icons.notes_rounded,
          'Nota',
          () => _addEvent('Nota', 'Nueva nota'),
        ),
        _EventAction(
          Icons.warning_amber_rounded,
          'Incidente',
          () => _addEvent('Incidente', 'Registrar incidente'),
        ),
        _EventAction(Icons.add_a_photo_outlined, 'Foto', _addPhoto),
      ],
    ),
  );

  Widget _summaryCard() => _Card(
    title: widget.walk.isCompleted ? 'Resumen del paseo' : 'Resumen en vivo',
    subtitle: 'Datos calculados con la ruta y la bitácora.',
    icon: Icons.insights_outlined,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(
                'Distancia',
                '${_number(_report['distanciaKilometros'])} km',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                'Duración',
                '${_report['duracionRealMinutos'] ?? 0} min',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric('GPS', '${_report['puntosTracking'] ?? 0} pts'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Metric('Agua', (_report['vecesAgua'] ?? 0).toString()),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric('Pipi', (_report['vecesPipi'] ?? 0).toString()),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Metric(
                'Incidentes',
                (_report['incidentes'] ?? 0).toString(),
              ),
            ),
          ],
        ),
        if (_report['fotoInicioUrl'] != null ||
            _report['fotoFinUrl'] != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Evidence('Inicio', _url(_report['fotoInicioUrl'])),
              ),
              const SizedBox(width: 9),
              Expanded(child: _Evidence('Final', _url(_report['fotoFinUrl']))),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _timelineCard() => _Card(
    title: 'Bitácora',
    subtitle: _events.isEmpty
        ? 'Todavía no hay eventos registrados.'
        : '${_events.length} momentos del paseo.',
    icon: Icons.timeline_rounded,
    child: _events.isEmpty
        ? const _EmptyTimeline()
        : Column(
            children: _events.reversed
                .map(
                  (event) =>
                      _EventRow(event: event, photoUrl: _url(event['fotoUrl'])),
                )
                .toList(growable: false),
          ),
  );

  Widget _toolsCard() {
    final sharing = _security['seguimientoCompartidoActivo'] == true;
    return _Card(
      title: 'Herramientas del paseo',
      subtitle: 'Comunicación, mapa y seguimiento desde un solo lugar.',
      icon: Icons.widgets_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Tool(
                  Icons.forum_outlined,
                  'Chat',
                  widget.canOpenChat,
                  widget.onChat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Tool(
                  Icons.map_outlined,
                  'Ruta',
                  widget.canOpenMap,
                  widget.onMap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Tool(
                  Icons.gps_fixed_rounded,
                  'En vivo',
                  widget.canOpenTracking,
                  widget.onTracking,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: sharing
                ? OutlinedButton.icon(
                    onPressed: _acting ? null : _revokeShare,
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Desactivar enlace compartido'),
                  )
                : FilledButton.icon(
                    onPressed: _acting ? null : _share,
                    icon: const Icon(Icons.share_location_outlined),
                    label: const Text('Compartir seguimiento temporal'),
                  ),
          ),
        ],
      ),
    );
  }

  String? _url(dynamic path) {
    final value = path?.toString().trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = widget.baseUrl?.replaceAll(RegExp(r'/+$'), '') ?? '';
    return base.isEmpty
        ? value
        : '$base/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String _number(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    return (parsed ?? 0).toStringAsFixed(2);
  }

  static String _clean(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiException: ', '')
      .trim();
}

class _Hero extends StatelessWidget {
  final WalkDetail walk;
  const _Hero({required this.walk});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [DogGoTheme.teal, DogGoTheme.tealDark],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        const SizedBox(height: 13),
        Text(
          walk.petsLabel,
          style: DogGoTheme.title(size: 25, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Text(
          '${walk.status.label} · ${walk.scheduledLabel} · ${walk.walkerName}',
          style: DogGoTheme.body(
            size: 11.5,
            color: Colors.white.withValues(alpha: .82),
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  const _Card({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: DogGoTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DogGoTheme.tealLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: DogGoTheme.teal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DogGoTheme.title(size: 17)),
                  Text(subtitle, style: DogGoTheme.subtitle(size: 10.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

class _PinValue extends StatelessWidget {
  final String label;
  final String value;
  const _PinValue(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DogGoTheme.tealLight,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DogGoTheme.body(size: 13, weight: FontWeight.w800),
          ),
        ),
        SelectableText(
          value,
          style: DogGoTheme.title(size: 23, color: DogGoTheme.teal),
        ),
      ],
    ),
  );
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool complete;
  const _StatusRow(this.label, this.complete);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        complete
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: complete ? DogGoTheme.green : DogGoTheme.muted,
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          label,
          style: DogGoTheme.body(size: 13, weight: FontWeight.w700),
        ),
      ),
      Text(
        complete ? 'Confirmada' : 'Pendiente',
        style: DogGoTheme.caption(
          size: 10,
          color: complete ? DogGoTheme.green : DogGoTheme.muted,
          weight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _EventAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _EventAction(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 18, color: DogGoTheme.teal),
    label: Text(label),
    onPressed: onTap,
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 12),
    decoration: BoxDecoration(
      color: DogGoTheme.cream,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DogGoTheme.body(
            size: 12,
            color: DogGoTheme.teal,
            weight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, maxLines: 1, style: DogGoTheme.caption(size: 9)),
      ],
    ),
  );
}

class _Evidence extends StatelessWidget {
  final String label;
  final String? url;
  const _Evidence(this.label, this.url);
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 1.4,
          child: DogGoNetworkImage(
            url: url,
            semanticLabel: 'Evidencia de $label',
            fallback: Container(
              color: DogGoTheme.tealLight,
              child: const Icon(Icons.photo_outlined, color: DogGoTheme.teal),
            ),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(label, style: DogGoTheme.caption(size: 10, weight: FontWeight.w800)),
    ],
  );
}

class _EventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final String? photoUrl;
  const _EventRow({required this.event, required this.photoUrl});
  @override
  Widget build(BuildContext context) {
    final type = (event['tipo'] ?? 'Evento').toString();
    final description = (event['descripcion'] ?? '').toString().trim();
    final date = DateTime.tryParse(
      (event['fechaUtc'] ?? '').toString(),
    )?.toLocal();
    final time = date == null
        ? ''
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: DogGoTheme.tealLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 18,
              color: DogGoTheme.teal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: DogGoTheme.body(
                          size: 12.5,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(time, style: DogGoTheme.caption(size: 9.5)),
                  ],
                ),
                if (description.isNotEmpty)
                  Text(description, style: DogGoTheme.subtitle(size: 11)),
                if (photoUrl != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 130,
                      width: double.infinity,
                      child: DogGoNetworkImage(
                        url: photoUrl,
                        semanticLabel: 'Foto de evento',
                        fallback: Container(
                          color: DogGoTheme.tealLight,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DogGoTheme.cream,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      'Aquí aparecerán la recogida, ruta, fotos, cuidados y entrega.',
      textAlign: TextAlign.center,
      style: DogGoTheme.subtitle(size: 11.5),
    ),
  );
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _Tool(this.icon, this.label, this.enabled, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: enabled ? DogGoTheme.tealLight : DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: enabled ? DogGoTheme.teal : DogGoTheme.disabled),
          const SizedBox(height: 5),
          Text(
            label,
            style: DogGoTheme.caption(size: 10, weight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
