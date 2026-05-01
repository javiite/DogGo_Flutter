import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/evidencia_service.dart';
import '../services/permiso_service.dart';

class EvidenciaPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String tipo;
  final String nombrePerro;
  final String nombrePaseador;

  const EvidenciaPaseoScreen({
    super.key,
    required this.paseoId,
    required this.tipo,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<EvidenciaPaseoScreen> createState() => _EvidenciaPaseoScreenState();
}

class _EvidenciaPaseoScreenState extends State<EvidenciaPaseoScreen> {
  final EvidenciaService _evidenciaService = EvidenciaService();
  final ImagePicker _picker = ImagePicker();

  File? _archivo;
  bool _subiendo = false;

  bool get _esInicio {
    return widget.tipo.toLowerCase() == 'inicio';
  }

  String get _titulo {
    return _esInicio ? 'Foto de inicio' : 'Foto de fin';
  }

  String get _descripcion {
    return _esInicio
        ? 'Sube una foto al iniciar el paseo como evidencia.'
        : 'Sube una foto al finalizar el paseo como evidencia.';
  }

  Color get _color {
    return _esInicio ? Colors.green : Colors.purple;
  }

  Future<void> _tomarFoto() async {
    final permiso = await PermisoService.pedirCamara();

    if (!permiso) {
      _mostrarDialogoPermiso();
      return;
    }

    final imagen = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1400,
    );

    if (imagen == null) return;

    setState(() {
      _archivo = File(imagen.path);
    });
  }

  Future<void> _elegirGaleria() async {
    final imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1400,
    );

    if (imagen == null) return;

    setState(() {
      _archivo = File(imagen.path);
    });
  }

  Future<void> _mostrarDialogoPermiso() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permiso de cámara'),
          content: const Text(
            'Para tomar una foto necesitas permitir el acceso a la cámara.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await PermisoService.abrirConfiguracion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
              ),
              child: const Text('Abrir configuración'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _subirEvidencia() async {
    final archivo = _archivo;

    if (archivo == null) {
      _mostrarMensaje('Selecciona o toma una foto primero.');
      return;
    }

    setState(() {
      _subiendo = true;
    });

    try {
      if (_esInicio) {
        await _evidenciaService.subirFotoInicio(
          paseoId: widget.paseoId,
          archivo: archivo,
        );
      } else {
        await _evidenciaService.subirFotoFin(
          paseoId: widget.paseoId,
          archivo: archivo,
        );
      }

      if (!mounted) return;

      _mostrarMensaje('Evidencia subida correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo subir la evidencia: $e');
    } finally {
      if (mounted) {
        setState(() {
          _subiendo = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text(_titulo),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPreview(),
            const SizedBox(height: 16),
            _buildBotonesSeleccion(),
            const SizedBox(height: 18),
            _buildBotonSubir(),
            const SizedBox(height: 14),
            _buildNota(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _color,
            _color.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.24),
              ),
            ),
            child: Icon(
              _esInicio
                  ? Icons.play_circle_fill_rounded
                  : Icons.flag_circle_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _descripcion,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Perro: ${widget.nombrePerro}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 310,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _archivo == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.grey.shade400,
                  size: 70,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Todavía no seleccionaste una foto.',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Puedes tomar una foto con la cámara o elegir una desde galería.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    _archivo!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: InkWell(
                    onTap: _subiendo
                        ? null
                        : () {
                            setState(() {
                              _archivo = null;
                            });
                          },
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBotonesSeleccion() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _subiendo ? null : _tomarFoto,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Cámara'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _subiendo ? null : _elegirGaleria,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galería'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F8A70),
                side: const BorderSide(
                  color: Color(0xFF1F8A70),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotonSubir() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _subiendo ? null : _subirEvidencia,
        icon: _subiendo
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_rounded),
        label: Text(_subiendo ? 'Subiendo...' : 'Subir evidencia'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildNota() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.blue,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La evidencia ayuda al dueño a comprobar el inicio y cierre del paseo.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}