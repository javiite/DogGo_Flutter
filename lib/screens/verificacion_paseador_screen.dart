import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/errors/api_exception.dart';
import '../services/paseador_verificacion_service.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_theme.dart';

class VerificacionPaseadorScreen extends StatefulWidget {
  const VerificacionPaseadorScreen({super.key});

  @override
  State<VerificacionPaseadorScreen> createState() =>
      _VerificacionPaseadorScreenState();
}

class _VerificacionPaseadorScreenState
    extends State<VerificacionPaseadorScreen> {
  static const int _maxBytes = 8 * 1024 * 1024;
  static const String _identificacion = 'IdentificacionOficial';
  static const String _domicilio = 'ComprobanteDomicilio';

  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _estado;
  bool _loading = true;
  bool _submitting = false;
  String? _uploadingType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await PaseadorVerificacionService.obtenerEstado();
      if (!mounted) return;
      setState(() {
        _estado = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _loading = false;
      });
    }
  }

  String get _status => _text(_estado?['estado'], fallback: 'SinSolicitud');

  bool get _documentsLocked => const {
    'pendiente',
    'enrevision',
    'aprobado',
  }.contains(_status.toLowerCase());

  bool get _canSubmit => _estado?['puedeSolicitar'] == true;

  int get _profilePercent {
    final value = _estado?['perfilPorcentaje'];
    if (value is num) return value.toInt().clamp(0, 100);
    return int.tryParse('$value')?.clamp(0, 100) ?? 0;
  }

  List<String> get _missingRequirements {
    final value = _estado?['requisitosFaltantes'];
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> get _documents {
    final value = _estado?['documentos'];
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic>? _document(String type) {
    for (final item in _documents) {
      if (_text(item['tipo'], fallback: '').toLowerCase() ==
          type.toLowerCase()) {
        return item;
      }
    }
    return null;
  }

  Future<void> _chooseSource(String type) async {
    if (_documentsLocked || _uploadingType != null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona el documento',
                style: DogGoTheme.title(size: 21),
              ),
              const SizedBox(height: 6),
              Text(
                'Toma una foto clara o elige una imagen de tu galería.',
                style: DogGoTheme.subtitle(size: 13),
              ),
              const SizedBox(height: 18),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: DogGoTheme.tealLight,
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: DogGoTheme.teal,
                ),
                title: Text(
                  'Tomar fotografía',
                  style: DogGoTheme.body(weight: FontWeight.w800),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: DogGoTheme.purpleLight,
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: DogGoTheme.purple,
                ),
                title: Text(
                  'Elegir de galería',
                  style: DogGoTheme.body(weight: FontWeight.w800),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _pickAndUpload(type, source);
  }

  Future<void> _pickAndUpload(String type, ImageSource source) async {
    try {
      final selected = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2200,
        maxHeight: 2200,
      );
      if (selected == null) return;

      final file = File(selected.path);
      final length = await file.length();
      if (length <= 0 || length > _maxBytes) {
        _show('La imagen debe pesar menos de 8 MB.', error: true);
        return;
      }

      if (!mounted) return;
      setState(() => _uploadingType = type);
      final message = await PaseadorVerificacionService.cargarDocumento(
        tipo: type,
        archivo: file,
      );
      if (!mounted) return;
      _show(message);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _show(_message(error), error: true);
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar a verificación'),
        content: const Text(
          'Después de enviar la solicitud no podrás reemplazar los documentos hasta que termine la revisión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      final message = await PaseadorVerificacionService.solicitarRevision();
      if (!mounted) return;
      _show(message);
      await _load();
    } catch (error) {
      if (!mounted) return;
      _show(_message(error), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? DogGoTheme.red : DogGoTheme.ink,
        ),
      );
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _text(dynamic value, {required String fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(
      title: 'Verificación profesional',
      actions: [
        IconButton(
          tooltip: 'Actualizar estado de verificación',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  if (_missingRequirements.isNotEmpty) ...[
                    _buildRequirementsCard(),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Documentos privados',
                    style: DogGoTheme.title(size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Solo el personal administrativo autorizado puede consultar estos archivos.',
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                  const SizedBox(height: 14),
                  _DocumentCard(
                    title: 'Identificación oficial',
                    description: 'INE, pasaporte o documento oficial vigente.',
                    document: _document(_identificacion),
                    loading: _uploadingType == _identificacion,
                    locked: _documentsLocked,
                    onUpload: () => _chooseSource(_identificacion),
                  ),
                  const SizedBox(height: 12),
                  _DocumentCard(
                    title: 'Comprobante de domicilio',
                    description:
                        'Recibo o constancia donde pueda verificarse tu domicilio.',
                    document: _document(_domicilio),
                    loading: _uploadingType == _domicilio,
                    locked: _documentsLocked,
                    onUpload: () => _chooseSource(_domicilio),
                  ),
                  const SizedBox(height: 18),
                  _buildPrivacyNote(),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _canSubmit && !_submitting ? _submit : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.verified_user_rounded),
                    label: Text(_submitting ? 'Enviando...' : _submitLabel),
                  ),
                  if (!_canSubmit && !_documentsLocked) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Completa el perfil y carga ambos documentos para habilitar el envío.',
                      textAlign: TextAlign.center,
                      style: DogGoTheme.subtitle(size: 12),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String get _submitLabel {
    switch (_status.toLowerCase()) {
      case 'pendiente':
        return 'Solicitud pendiente';
      case 'enrevision':
        return 'Solicitud en revisión';
      case 'aprobado':
        return 'Perfil verificado';
      default:
        return 'Enviar solicitud de verificación';
    }
  }

  Widget _buildStatusCard() {
    final presentation = _StatusPresentation.from(_status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: presentation.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: presentation.color.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(presentation.icon, color: presentation.color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(presentation.title, style: DogGoTheme.title(size: 20)),
                    const SizedBox(height: 3),
                    Text(
                      presentation.description,
                      style: DogGoTheme.subtitle(size: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Perfil completado',
                  style: DogGoTheme.body(weight: FontWeight.w800),
                ),
              ),
              Text(
                '$_profilePercent%',
                style: DogGoTheme.body(
                  color: presentation.color,
                  weight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: _profilePercent / 100,
              color: presentation.color,
              backgroundColor: Colors.white.withValues(alpha: .85),
            ),
          ),
          if (_text(_estado?['motivoRevision'], fallback: '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Observación: ${_text(_estado?['motivoRevision'], fallback: '')}',
                style: DogGoTheme.body(size: 12.5, weight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DogGoTheme.orange.withValues(alpha: .28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_late_rounded,
                color: DogGoTheme.orange,
              ),
              const SizedBox(width: 9),
              Text('Completa tu perfil', style: DogGoTheme.title(size: 17)),
            ],
          ),
          const SizedBox(height: 10),
          ..._missingRequirements.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 7, color: DogGoTheme.orange),
                  const SizedBox(width: 9),
                  Expanded(child: Text(item, style: DogGoTheme.body(size: 13))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DogGoTheme.tealLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_rounded, color: DogGoTheme.teal),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Tus documentos se almacenan de forma privada. Nunca se muestran a otros usuarios ni en tu perfil público.',
              style: DogGoTheme.body(size: 12.5, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String title;
  final String description;
  final Map<String, dynamic>? document;
  final bool loading;
  final bool locked;
  final VoidCallback onUpload;

  const _DocumentCard({
    required this.title,
    required this.description,
    required this.document,
    required this.loading,
    required this.locked,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = document != null;
    final name = document?['nombreOriginal']?.toString().trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: uploaded
              ? DogGoTheme.green.withValues(alpha: .35)
              : DogGoTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: uploaded
                      ? DogGoTheme.greenLight
                      : DogGoTheme.purpleLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  uploaded ? Icons.task_alt_rounded : Icons.badge_outlined,
                  color: uploaded ? DogGoTheme.green : DogGoTheme.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DogGoTheme.title(size: 17)),
                    const SizedBox(height: 3),
                    Text(
                      uploaded ? 'Documento cargado' : 'Documento pendiente',
                      style: DogGoTheme.body(
                        size: 12,
                        color: uploaded ? DogGoTheme.green : DogGoTheme.orange,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: DogGoTheme.subtitle(size: 12.5)),
          if (uploaded && name != null && name.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DogGoTheme.body(size: 12.5, weight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: locked || loading ? null : onUpload,
              icon: loading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      uploaded
                          ? Icons.refresh_rounded
                          : Icons.upload_file_rounded,
                    ),
              label: Text(
                loading
                    ? 'Subiendo...'
                    : locked
                    ? 'Documento bloqueado durante revisión'
                    : uploaded
                    ? 'Reemplazar documento'
                    : 'Cargar documento',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPresentation {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color surface;

  const _StatusPresentation({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.surface,
  });

  factory _StatusPresentation.from(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return const _StatusPresentation(
          title: 'Solicitud pendiente',
          description: 'Tu expediente fue recibido y espera revisión.',
          icon: Icons.hourglass_top_rounded,
          color: DogGoTheme.orange,
          surface: DogGoTheme.orangeLight,
        );
      case 'enrevision':
        return const _StatusPresentation(
          title: 'Verificación en revisión',
          description: 'El equipo DogGo está revisando tus documentos.',
          icon: Icons.manage_search_rounded,
          color: DogGoTheme.purple,
          surface: DogGoTheme.purpleLight,
        );
      case 'aprobado':
        return const _StatusPresentation(
          title: 'Perfil verificado',
          description:
              'Ya puedes aparecer ante los dueños y recibir solicitudes.',
          icon: Icons.verified_rounded,
          color: DogGoTheme.green,
          surface: DogGoTheme.greenLight,
        );
      case 'rechazado':
      case 'requierecambios':
        return const _StatusPresentation(
          title: 'Necesitamos algunos cambios',
          description:
              'Consulta la observación, corrige el expediente y vuelve a enviarlo.',
          icon: Icons.edit_document,
          color: DogGoTheme.red,
          surface: DogGoTheme.redLight,
        );
      case 'borrador':
        return const _StatusPresentation(
          title: 'Expediente en preparación',
          description: 'Carga ambos documentos para solicitar la revisión.',
          icon: Icons.folder_open_rounded,
          color: DogGoTheme.teal,
          surface: DogGoTheme.tealLight,
        );
      default:
        return const _StatusPresentation(
          title: 'Comienza tu verificación',
          description: 'Prepara tu perfil profesional y tus documentos.',
          icon: Icons.verified_user_outlined,
          color: DogGoTheme.teal,
          surface: DogGoTheme.tealLight,
        );
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: DogGoTheme.red,
            ),
            const SizedBox(height: 14),
            Text(
              'No pudimos cargar tu verificación',
              style: DogGoTheme.title(size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: DogGoTheme.subtitle(size: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
