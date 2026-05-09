import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perros_service.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);
  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);
  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);
  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);
  static const rose = Color(0xFFEF4444);
  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .055,
    double blur = 16,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double spacing = 0,
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

class RegistrarPerroScreen extends StatefulWidget {
  const RegistrarPerroScreen({super.key});

  @override
  State<RegistrarPerroScreen> createState() => _RegistrarPerroScreenState();
}

class _RegistrarPerroScreenState extends State<RegistrarPerroScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _fotoUrlController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _tamanoSeleccionado = 'Mediano';
  XFile? _imagenLocal;
  bool _guardando = false;

  final List<String> _tamanos = const [
    'Pequeño',
    'Mediano',
    'Grande',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _notasController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _mostrarOpcionesFoto() async {
    if (_guardando) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: _T.shadow(
                opacity: .12,
                blur: 24,
                offset: const Offset(0, 8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _T.stroke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Foto del perro',
                  style: _ts(18, FontWeight.w900, _T.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige una foto existente o toma una nueva con la cámara.',
                  textAlign: TextAlign.center,
                  style: _ts(12.5, FontWeight.w600, _T.inkSub, height: 1.35),
                ),
                const SizedBox(height: 16),
                _BottomOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir desde galería',
                  subtitle: 'Seleccionar una imagen del celular',
                  color: _T.teal,
                  surface: _T.tealSurface,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
                _BottomOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar foto con cámara',
                  subtitle: 'Abrir cámara y tomar foto ahora',
                  color: _T.violet,
                  surface: _T.violetSurf,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (_imagenLocal != null) ...[
                  const SizedBox(height: 10),
                  _BottomOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Quitar foto seleccionada',
                    subtitle: 'Guardar el perro sin esta imagen',
                    color: _T.rose,
                    surface: const Color(0xFFFEEEEE),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imagenLocal = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    await _seleccionarImagen(source);
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final imagen = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (imagen == null) return;

      setState(() {
        _imagenLocal = imagen;
      });

      _mostrarMensaje(
        source == ImageSource.camera
            ? 'Foto tomada. Se subirá al guardar el perro.'
            : 'Foto seleccionada. Se subirá al guardar el perro.',
      );
    } catch (e) {
      _mostrarMensaje('No se pudo obtener la imagen: $e');
    }
  }

  bool _validar() {
    final nombre = _nombreController.text.trim();
    final raza = _razaController.text.trim();
    final edadTexto = _edadController.text.trim();

    if (nombre.isEmpty) {
      _mostrarMensaje('Escribe el nombre del perro.');
      return false;
    }

    if (raza.isEmpty) {
      _mostrarMensaje('Escribe la raza del perro.');
      return false;
    }

    if (edadTexto.isEmpty) {
      _mostrarMensaje('Escribe la edad del perro.');
      return false;
    }

    final edad = int.tryParse(edadTexto);

    if (edad == null) {
      _mostrarMensaje('La edad debe ser un número válido.');
      return false;
    }

    if (edad < 0 || edad > 30) {
      _mostrarMensaje('La edad debe estar entre 0 y 30 años.');
      return false;
    }

    final fotoUrl = _fotoUrlController.text.trim();

    if (fotoUrl.isNotEmpty &&
        !fotoUrl.startsWith('http://') &&
        !fotoUrl.startsWith('https://') &&
        !fotoUrl.startsWith('/')) {
      _mostrarMensaje(
        'La foto debe ser URL http/https o una ruta del servidor que empiece con /',
      );
      return false;
    }

    return true;
  }

  int? _extraerIdPerro(dynamic data) {
    if (data == null) return null;

    if (data is int) return data;

    if (data is String) {
      return int.tryParse(data);
    }

    if (data is Map) {
      final keys = [
        'id',
        'Id',
        'perroId',
        'PerroId',
        'idPerro',
        'IdPerro',
      ];

      for (final key in keys) {
        final value = data[key];

        if (value is int) return value;
        if (value is num) return value.toInt();

        final parsed = int.tryParse(value?.toString() ?? '');

        if (parsed != null) return parsed;
      }

      final perro = data['perro'] ?? data['Perro'] ?? data['data'] ?? data['Data'];

      if (perro != null && perro != data) {
        return _extraerIdPerro(perro);
      }
    }

    return null;
  }

  Future<void> _guardarPerro() async {
    if (_guardando) return;

    if (!_validar()) return;

    final edad = int.parse(_edadController.text.trim());
    final fotoUrlManual = _fotoUrlController.text.trim();
    final tieneImagenLocal = _imagenLocal != null;

    setState(() {
      _guardando = true;
    });

    try {
      final result = await PerrosService.registrarPerro(
        nombre: _nombreController.text.trim(),
        raza: _razaController.text.trim(),
        edad: edad,
        tamano: _tamanoSeleccionado,
        notas: _notasController.text.trim(),
        fotoUrl: tieneImagenLocal
            ? null
            : fotoUrlManual.isEmpty
                ? null
                : fotoUrlManual,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        String mensajeFinal =
            result['message']?.toString() ?? 'Perro registrado correctamente.';

        if (tieneImagenLocal) {
          final idPerro = _extraerIdPerro(result['data']);

          if (idPerro == null) {
            mensajeFinal =
                'Perro registrado, pero no se encontró el ID para subir la foto.';
          } else {
            final fotoResult = await PerrosService.subirFotoPerro(
              id: idPerro,
              filePath: _imagenLocal!.path,
            );

            if (!mounted) return;

            if (fotoResult['success'] == true) {
              mensajeFinal = 'Perro registrado con foto correctamente.';
            } else {
              final statusCode = fotoResult['statusCode'];
              final errorFoto = fotoResult['message']?.toString() ??
                  'No se pudo subir la foto.';

              mensajeFinal = statusCode == null
                  ? 'Perro registrado, pero la foto no se subió: $errorFoto'
                  : 'Perro registrado, pero la foto no se subió: $errorFoto Código: $statusCode';
            }
          }
        }

        _mostrarMensaje(mensajeFinal);

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        Navigator.pop(context, true);
      } else {
        final statusCode = result['statusCode'];

        _mostrarMensaje(
          statusCode == null
              ? result['message']?.toString() ?? 'No se pudo registrar el perro.'
              : '${result['message']} Código: $statusCode',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  InputDecoration _decoracionCampo({
    required String label,
    required IconData icon,
    String? hint,
    Color color = _T.teal,
    Color surface = _T.tealSurface,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F4EC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: color,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombrePreview = _nombreController.text.trim().isEmpty
        ? 'Nuevo perro'
        : _nombreController.text.trim();

    final razaPreview = _razaController.text.trim().isEmpty
        ? 'Raza'
        : _razaController.text.trim();

    final edadPreview = _edadController.text.trim().isEmpty
        ? 'Edad'
        : '${_edadController.text.trim()} años';

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('🐶', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Registrar perro',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _HeaderNuevoPerro(
            nombre: nombrePreview,
            raza: razaPreview,
            edad: edadPreview,
            tamano: _tamanoSeleccionado,
            imagenLocal: _imagenLocal,
            fotoUrl: _fotoUrlController.text.trim(),
            onPickImage: () {
              _mostrarOpcionesFoto();
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                _FormCard(
                  titulo: '🐾 Datos del perro',
                  child: Column(
                    children: [
                      TextField(
                        controller: _nombreController,
                        enabled: !_guardando,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          label: 'Nombre',
                          icon: Icons.pets_rounded,
                          hint: 'Ej. Max',
                          color: _T.teal,
                          surface: _T.tealSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _razaController,
                        enabled: !_guardando,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          label: 'Raza',
                          icon: Icons.badge_outlined,
                          hint: 'Ej. Labrador',
                          color: _T.violet,
                          surface: _T.violetSurf,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _edadController,
                        enabled: !_guardando,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          label: 'Edad',
                          icon: Icons.cake_outlined,
                          hint: 'Ej. 3',
                          color: _T.amber,
                          surface: _T.amberSurf,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DropdownTamano(
                        value: _tamanoSeleccionado,
                        enabled: !_guardando,
                        tamanos: _tamanos,
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _tamanoSeleccionado = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormCard(
                  titulo: '📷 Foto del perro',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _imagenLocal == null
                            ? 'Puedes guardar el perro sin foto, elegir una imagen de galería o tomar una foto con cámara.'
                            : 'Foto lista. Se subirá al servidor cuando guardes el perro.',
                        style: _ts(
                          12.5,
                          FontWeight.w700,
                          _imagenLocal == null ? _T.inkSub : _T.tealDeep,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : () => _seleccionarImagen(
                                        ImageSource.gallery,
                                      ),
                              icon: const Icon(Icons.photo_library_rounded),
                              label: const Text('Galería'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _T.tealDeep,
                                side: const BorderSide(color: _T.tealDeep),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : () => _seleccionarImagen(
                                        ImageSource.camera,
                                      ),
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Cámara'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _T.violet,
                                side: const BorderSide(color: _T.violet),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fotoUrlController,
                        enabled: !_guardando && _imagenLocal == null,
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          label: 'URL o ruta manual opcional',
                          icon: Icons.link_rounded,
                          hint: 'Ej. /uploads/perros/max.jpg',
                          color: _T.emerald,
                          surface: _T.emeraldSurf,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este campo es opcional. Si eliges cámara o galería, se usará esa imagen y se ignorará la ruta manual.',
                        style: _ts(11.5, FontWeight.w600, _T.inkSub, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _FormCard(
                  titulo: '📝 Notas',
                  child: TextField(
                    controller: _notasController,
                    enabled: !_guardando,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Cuidados, temperamento, alergias, etc.',
                      filled: true,
                      fillColor: const Color(0xFFF8F4EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarPerro,
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_guardando ? 'Guardando...' : 'Guardar perro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _T.teal.withOpacity(.45),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderNuevoPerro extends StatelessWidget {
  final String nombre;
  final String raza;
  final String edad;
  final String tamano;
  final XFile? imagenLocal;
  final String fotoUrl;
  final VoidCallback onPickImage;

  const _HeaderNuevoPerro({
    required this.nombre,
    required this.raza,
    required this.edad,
    required this.tamano,
    required this.imagenLocal,
    required this.fotoUrl,
    required this.onPickImage,
  });

  bool get _tieneFotoUrl {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF089B7A),
            Color(0xFFF4F0E8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: _T.shadow(
              opacity: .075,
              blur: 22,
              offset: const Offset(0, 8),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildImage(),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(.02),
                              Colors.black.withOpacity(.34),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _Tag(
                        text: tamano,
                        color: _T.tealDeep,
                        background: Colors.white.withOpacity(.94),
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Material(
                        color: Colors.white.withOpacity(.94),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onPickImage,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.add_a_photo_rounded,
                              color: _T.tealDeep,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(
                              31,
                              FontWeight.w900,
                              Colors.white,
                              spacing: -.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(
                                text: raza,
                                color: _T.tealDeep,
                                background: Colors.white.withOpacity(.92),
                              ),
                              _Tag(
                                text: edad,
                                color: _T.violet,
                                background: Colors.white.withOpacity(.92),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  children: [
                    Text(
                      'NUEVO PELUDO',
                      style: _ts(11, FontWeight.w900, _T.tealDeep, spacing: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Agrega la información básica de tu mascota para poder solicitar paseos.',
                      textAlign: TextAlign.center,
                      style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imagenLocal != null) {
      return Image.file(
        File(imagenLocal!.path),
        fit: BoxFit.cover,
      );
    }

    if (_tieneFotoUrl) {
      return Image.network(
        fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _LargeDogPlaceholder(),
      );
    }

    return const _LargeDogPlaceholder();
  }
}

class _DropdownTamano extends StatelessWidget {
  final String value;
  final bool enabled;
  final List<String> tamanos;
  final void Function(String?) onChanged;

  const _DropdownTamano({
    required this.value,
    required this.enabled,
    required this.tamanos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: tamanos.map((tamano) {
            return DropdownMenuItem<String>(
              value: tamano,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _T.violetSurf,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.straighten_rounded,
                      color: _T.violet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(tamano),
                ],
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _LargeDogPlaceholder extends StatelessWidget {
  const _LargeDogPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.tealSurface,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -45,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _T.teal.withOpacity(.13),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: _T.violet.withOpacity(.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Text(
              '🐶',
              style: TextStyle(
                fontSize: 92,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _FormCard({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _T.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: _ts(15, FontWeight.w900, _T.ink, spacing: -.2),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BottomOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  const _BottomOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _ts(13.5, FontWeight.w900, _T.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _ts(11.5, FontWeight.w600, _T.inkSub),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _Tag({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: _ts(11, FontWeight.w900, color),
      ),
    );
  }
}