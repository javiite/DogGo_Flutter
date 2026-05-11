import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/perros_service.dart';
import '../services/storage_service.dart';
import '../widgets/doggo_logo.dart';

class EditarPerroScreen extends StatefulWidget {
  final Map<String, dynamic> perro;

  const EditarPerroScreen({
    super.key,
    required this.perro,
  });

  @override
  State<EditarPerroScreen> createState() => _EditarPerroScreenState();
}

class _EditarPerroScreenState extends State<EditarPerroScreen> {
  late final TextEditingController _nombreController;
  late final TextEditingController _razaController;
  late final TextEditingController _edadController;
  late final TextEditingController _notasController;
  late final TextEditingController _fotoUrlController;

  final ImagePicker _picker = ImagePicker();

  String _tamanoSeleccionado = 'Mediano';
  String? _baseUrl;
  XFile? _imagenLocal;
  bool _guardando = false;

  final List<String> _tamanos = const [
    'Pequeño',
    'Mediano',
    'Grande',
  ];

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: _texto(
        _valor(
          [
            'nombre',
            'Nombre',
            'nombrePerro',
            'NombrePerro',
          ],
        ),
        fallback: '',
      ),
    );

    _razaController = TextEditingController(
      text: _texto(
        _valor(
          [
            'raza',
            'Raza',
          ],
        ),
        fallback: '',
      ),
    );

    _edadController = TextEditingController(
      text: _texto(
        _valor(
          [
            'edad',
            'Edad',
          ],
        ),
        fallback: '',
      ),
    );

    final tamanoInicial = _texto(
      _valor(
        [
          'tamano',
          'Tamano',
          'tamanio',
          'Tamanio',
          'tamaño',
          'Tamaño',
        ],
      ),
      fallback: 'Mediano',
    );

    _tamanoSeleccionado =
        _tamanos.contains(tamanoInicial) ? tamanoInicial : 'Mediano';

    _notasController = TextEditingController(
      text: _texto(
        _valor(
          [
            'notas',
            'Notas',
            'nota',
            'Nota',
            'descripcion',
            'Descripcion',
            'observaciones',
            'Observaciones',
          ],
        ),
        fallback: '',
      ),
    );

    _fotoUrlController = TextEditingController(
      text: _texto(
        _valor(
          [
            'fotoUrl',
            'FotoUrl',
            'foto',
            'Foto',
            'urlFoto',
            'UrlFoto',
            'imagenUrl',
            'ImagenUrl',
            'imagen',
            'Imagen',
            'fotoPerroUrl',
            'FotoPerroUrl',
          ],
        ),
        fallback: '',
      ),
    );

    _cargarBaseUrl();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _notasController.dispose();
    _fotoUrlController.dispose();
    super.dispose();
  }

  Future<void> _cargarBaseUrl() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = baseUrl;
    });
  }

  dynamic _valor(List<String> keys) {
    for (final key in keys) {
      if (widget.perro.containsKey(key) && widget.perro[key] != null) {
        return widget.perro[key];
      }
    }

    return null;
  }

  String _texto(dynamic valor, {String fallback = 'Sin dato'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  int? _idPerro() {
    final valor = _valor(
      [
        'id',
        'Id',
        'perroId',
        'PerroId',
        'idPerro',
        'IdPerro',
      ],
    );

    if (valor is int) return valor;

    return int.tryParse(valor?.toString() ?? '');
  }

  String _fotoPreviewUrl() {
    final raw = _fotoUrlController.text.trim();

    if (raw.isEmpty) return '';

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return '';

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
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
              color: _DogGoWeb.card,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _DogGoWeb.shadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _DogGoWeb.stroke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Foto del perro',
                  style: _DogGoWeb.title(21),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige una foto existente o toma una nueva con la cámara.',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13),
                ),
                const SizedBox(height: 16),
                _BottomOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir desde galería',
                  subtitle: 'Seleccionar una imagen del celular',
                  color: _DogGoWeb.teal,
                  surface: _DogGoWeb.tealLight,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 10),
                _BottomOption(
                  icon: Icons.camera_alt_rounded,
                  title: 'Tomar foto con cámara',
                  subtitle: 'Abrir cámara y tomar foto ahora',
                  color: _DogGoWeb.purple,
                  surface: _DogGoWeb.purpleLight,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                if (_imagenLocal != null) ...[
                  const SizedBox(height: 10),
                  _BottomOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Quitar foto seleccionada',
                    subtitle: 'Mantener la foto actual del servidor',
                    color: _DogGoWeb.rose,
                    surface: _DogGoWeb.roseLight,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imagenLocal = null;
                      });
                    },
                  ),
                ],
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
            ? 'Foto tomada. Se subirá al guardar cambios.'
            : 'Foto seleccionada. Se subirá al guardar cambios.',
      );
    } catch (e) {
      _mostrarMensaje('No se pudo obtener la imagen: $e');
    }
  }

  bool _validar() {
    final nombre = _nombreController.text.trim();
    final raza = _razaController.text.trim();
    final edadTexto = _edadController.text.trim();
    final fotoUrl = _fotoUrlController.text.trim();

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

    if (_imagenLocal == null &&
        fotoUrl.isNotEmpty &&
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

  Future<void> _guardar() async {
    if (_guardando) return;

    if (!_validar()) return;

    final id = _idPerro();

    if (id == null) {
      _mostrarMensaje('No se encontró el ID del perro.');
      return;
    }

    final edad = int.parse(_edadController.text.trim());
    final fotoUrlManual = _fotoUrlController.text.trim();
    final tieneImagenLocal = _imagenLocal != null;

    setState(() {
      _guardando = true;
    });

    try {
      final result = await PerrosService.editarPerro(
        id: id,
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
            result['message']?.toString() ?? 'Perro actualizado correctamente.';

        if (tieneImagenLocal) {
          final fotoResult = await PerrosService.subirFotoPerro(
            id: id,
            filePath: _imagenLocal!.path,
          );

          if (!mounted) return;

          if (fotoResult['success'] == true) {
            mensajeFinal = 'Perro actualizado con foto correctamente.';
          } else {
            final statusCode = fotoResult['statusCode'];
            final errorFoto = fotoResult['message']?.toString() ??
                'No se pudo subir la foto.';

            mensajeFinal = statusCode == null
                ? 'Datos actualizados, pero la foto no se subió: $errorFoto'
                : 'Datos actualizados, pero la foto no se subió: $errorFoto Código: $statusCode';
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
              ? result['message']?.toString() ??
                  'No se pudo actualizar el perro.'
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
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _DogGoWeb.tealDeep,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _DogGoWeb.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _DogGoWeb.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: _DogGoWeb.teal,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombrePreview = _nombreController.text.trim().isEmpty
        ? 'Perro'
        : _nombreController.text.trim();

    return Scaffold(
      backgroundColor: _DogGoWeb.bg,
      body: SafeArea(
        child: _PatternBackground(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              const _TopWebBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                  decoration: BoxDecoration(
                    color: _DogGoWeb.card.withOpacity(.96),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _DogGoWeb.stroke),
                    boxShadow: _DogGoWeb.shadow(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✏️ EDITAR MASCOTA',
                        style: _DogGoWeb.label(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Editar perro',
                        style: _DogGoWeb.title(34),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Actualiza la información de tu mascota para que los paseos sean más seguros y personalizados.',
                        style: _DogGoWeb.subtitle(16),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            _PhotoPreview(
                              imagenLocal: _imagenLocal,
                              fotoUrl: _fotoPreviewUrl(),
                              onPickImage: _mostrarOpcionesFoto,
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: _guardando
                                  ? null
                                  : _mostrarOpcionesFoto,
                              icon: const Icon(Icons.camera_alt_rounded),
                              label: const Text('Cambiar foto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _DogGoWeb.cream,
                                foregroundColor: _DogGoWeb.ink,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'La foto nueva se subirá al guardar cambios.',
                              textAlign: TextAlign.center,
                              style: _DogGoWeb.subtitle(13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _Label('Nombre'),
                      TextField(
                        controller: _nombreController,
                        enabled: !_guardando,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          hint: 'Ej. Max',
                          icon: Icons.pets_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Label('Raza'),
                      TextField(
                        controller: _razaController,
                        enabled: !_guardando,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          hint: 'Ej. Golden Retriever',
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Label('Edad (años)'),
                      TextField(
                        controller: _edadController,
                        enabled: !_guardando,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: _decoracionCampo(
                          hint: 'Ej. 3',
                          icon: Icons.cake_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Label('Tamaño'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _DogGoWeb.stroke),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _tamanoSeleccionado,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            items: _tamanos.map((tamano) {
                              return DropdownMenuItem<String>(
                                value: tamano,
                                child: Text(tamano),
                              );
                            }).toList(),
                            onChanged: _guardando
                                ? null
                                : (value) {
                                    if (value == null) return;

                                    setState(() {
                                      _tamanoSeleccionado = value;
                                    });
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Label('Notas especiales'),
                      TextField(
                        controller: _notasController,
                        enabled: !_guardando,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText:
                              'Alergias, comportamiento, instrucciones para el paseador...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: _DogGoWeb.stroke),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: _DogGoWeb.stroke),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: _DogGoWeb.teal,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AdvancedPhotoPath(
                        controller: _fotoUrlController,
                        enabled: !_guardando && _imagenLocal == null,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _guardando ? null : _guardar,
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
                          label: Text(
                            _guardando
                                ? 'Guardando...'
                                : 'Guardar cambios 🐾',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _DogGoWeb.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _DogGoWeb.teal.withOpacity(.45),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _guardando
                              ? null
                              : () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _DogGoWeb.muted,
                            side: const BorderSide(color: _DogGoWeb.stroke),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Editando: $nombrePreview',
                          style: _DogGoWeb.subtitle(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _FooterDogGo(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopWebBar extends StatelessWidget {
  const _TopWebBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.08),
          ),
        ),
      ),
      child: Row(
        children: [
          const DogGoLogo(size: 58),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(
              Icons.close_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final XFile? imagenLocal;
  final String fotoUrl;
  final VoidCallback onPickImage;

  const _PhotoPreview({
    required this.imagenLocal,
    required this.fotoUrl,
    required this.onPickImage,
  });

  bool get _tieneFotoUrl {
    return fotoUrl.startsWith('http://') || fotoUrl.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: _DogGoWeb.tealLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: _DogGoWeb.shadow(),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImage(),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _DogGoWeb.purple,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
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
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Text(
              '🐶',
              style: TextStyle(fontSize: 56),
            ),
          );
        },
      );
    }

    return const Center(
      child: Text(
        '🐶',
        style: TextStyle(fontSize: 56),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: _DogGoWeb.body(
          14,
          color: _DogGoWeb.ink,
          weight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AdvancedPhotoPath extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  const _AdvancedPhotoPath({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_AdvancedPhotoPath> createState() => _AdvancedPhotoPathState();
}

class _AdvancedPhotoPathState extends State<_AdvancedPhotoPath> {
  bool _mostrar = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _mostrar = !_mostrar;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _DogGoWeb.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _DogGoWeb.stroke),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: _DogGoWeb.tealDeep,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ruta manual de foto',
                    style: _DogGoWeb.body(
                      13,
                      color: _DogGoWeb.ink,
                      weight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  _mostrar
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _DogGoWeb.muted,
                ),
              ],
            ),
          ),
        ),
        if (_mostrar) ...[
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            onChanged: (_) => widget.onChanged(),
            decoration: InputDecoration(
              hintText: 'Ej. /uploads/perros/max.jpg',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.image_rounded,
                color: _DogGoWeb.tealDeep,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _DogGoWeb.stroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: _DogGoWeb.stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: _DogGoWeb.teal,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Normalmente no tienes que tocar esto. Usa cámara o galería.',
            style: _DogGoWeb.subtitle(12),
          ),
        ],
      ],
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
                      style: _DogGoWeb.body(
                        14,
                        color: _DogGoWeb.ink,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _DogGoWeb.subtitle(12),
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

class _FooterDogGo extends StatelessWidget {
  const _FooterDogGo();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DogGoWeb.tealLight.withOpacity(.45),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        children: [
          const DogGoLogo(size: 42),
          const SizedBox(height: 10),
          Text(
            'DogGo © 2026 — Proyecto universitario',
            style: _DogGoWeb.subtitle(13),
          ),
        ],
      ),
    );
  }
}

class _PatternBackground extends StatelessWidget {
  final Widget child;

  const _PatternBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DogPatternPainter(),
      child: child,
    );
  }
}

class _DogPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _DogGoWeb.teal.withOpacity(.10)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const stepX = 82.0;
    const stepY = 82.0;

    for (double y = 30; y < size.height + stepY; y += stepY) {
      for (double x = 22; x < size.width + stepX; x += stepX) {
        final shiftedX = x + ((y ~/ stepY) % 2 == 0 ? 0 : 34);

        _drawPaw(canvas, paint, Offset(shiftedX, y));
        _drawBone(canvas, paint, Offset(shiftedX + 38, y + 38));
      }
    }
  }

  void _drawPaw(Canvas canvas, Paint paint, Offset c) {
    canvas.drawCircle(c + const Offset(0, 7), 7, paint);
    canvas.drawCircle(c + const Offset(-9, -2), 3.8, paint);
    canvas.drawCircle(c + const Offset(-3, -8), 3.8, paint);
    canvas.drawCircle(c + const Offset(5, -8), 3.8, paint);
    canvas.drawCircle(c + const Offset(11, -2), 3.8, paint);
  }

  void _drawBone(Canvas canvas, Paint paint, Offset c) {
    canvas.drawLine(
      c + const Offset(-11, -11),
      c + const Offset(11, 11),
      paint,
    );

    canvas.drawCircle(c + const Offset(-15, -13), 4, paint);
    canvas.drawCircle(c + const Offset(-9, -17), 4, paint);
    canvas.drawCircle(c + const Offset(15, 13), 4, paint);
    canvas.drawCircle(c + const Offset(9, 17), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DogGoWeb {
  static const teal = Color(0xFF009C8C);
  static const tealDeep = Color(0xFF087E73);
  static const tealLight = Color(0xFFD9F5EF);

  static const purple = Color(0xFF7156C8);
  static const purpleLight = Color(0xFFEDE7FA);

  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEEEEE);

  static const bg = Color(0xFFF5F0E8);
  static const cream = Color(0xFFFFF4E8);
  static const card = Colors.white;
  static const ink = Color(0xFF202033);
  static const muted = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E1DA);

  static TextStyle title(double size) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: ink,
      letterSpacing: -.6,
      height: 1.08,
    );
  }

  static TextStyle subtitle(double size) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: muted,
      height: 1.35,
    );
  }

  static TextStyle label() {
    return const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: tealDeep,
      letterSpacing: 1.6,
    );
  }

  static TextStyle body(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.25,
    );
  }

  static List<BoxShadow> shadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.06),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ];
  }
}