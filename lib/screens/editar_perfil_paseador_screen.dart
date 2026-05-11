import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/paseadores_service.dart';
import '../services/storage_service.dart';
import '../widgets/doggo_logo.dart';
import '../widgets/doggo_pattern_background.dart';

class EditarPerfilPaseadorScreen extends StatefulWidget {
  const EditarPerfilPaseadorScreen({super.key});

  @override
  State<EditarPerfilPaseadorScreen> createState() =>
      _EditarPerfilPaseadorScreenState();
}

class _EditarPerfilPaseadorScreenState
    extends State<EditarPerfilPaseadorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _zonaController = TextEditingController();
  final TextEditingController _tarifaController = TextEditingController();
  final TextEditingController _experienciaController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  bool _disponible = true;

  Map<String, dynamic>? _perfil;
  File? _imagenSeleccionada;
  String? _fotoActualUrl;
  String? _baseUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _zonaController.dispose();
    _tarifaController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _cargarBaseUrl();
    await _cargarPerfilPaseador();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = url;
    });
  }

  Future<void> _cargarPerfilPaseador() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final perfil = await PaseadoresService.obtenerMiPerfilPaseador();

      if (!mounted) return;

      _perfil = perfil;

      _descripcionController.text = _texto(
        perfil['descripcion'] ?? perfil['Descripcion'],
        fallback: '',
      );

      _zonaController.text = _texto(
        perfil['zonaServicio'] ??
            perfil['ZonaServicio'] ??
            perfil['zona'] ??
            perfil['Zona'],
        fallback: '',
      );

      _tarifaController.text = _numeroTexto(
        perfil['tarifaPorHora'] ??
            perfil['TarifaPorHora'] ??
            perfil['tarifa'] ??
            perfil['Tarifa'],
      );

      _experienciaController.text = _enteroTexto(
        perfil['experienciaAnios'] ??
            perfil['ExperienciaAnios'] ??
            perfil['experiencia'] ??
            perfil['Experiencia'],
      );

      final disponibleValor = perfil['disponible'] ?? perfil['Disponible'];

      if (disponibleValor is bool) {
        _disponible = disponibleValor;
      } else {
        _disponible = disponibleValor?.toString().toLowerCase() != 'false';
      }

      _fotoActualUrl = _urlPublica(
        perfil['fotoUrl'] ??
            perfil['FotoUrl'] ??
            perfil['imagenUrl'] ??
            perfil['ImagenUrl'],
      );

      setState(() {
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String _numeroTexto(dynamic valor) {
    if (valor == null) return '';

    final numero = double.tryParse(valor.toString());

    if (numero == null || numero == 0) return '';

    if (numero % 1 == 0) {
      return numero.toInt().toString();
    }

    return numero.toStringAsFixed(2);
  }

  String _enteroTexto(dynamic valor) {
    if (valor == null) return '';

    final numero = int.tryParse(valor.toString());

    if (numero == null || numero == 0) return '';

    return numero.toString();
  }

  String? _urlPublica(dynamic valor) {
    final raw = valor?.toString().trim();

    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final base = _baseUrl?.trim() ?? '';

    if (base.isEmpty) return raw;

    if (raw.startsWith('/')) {
      return '$base$raw';
    }

    return '$base/$raw';
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String? _validarDescripcion(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe una descripción.';
    }

    if (texto.length < 20) {
      return 'Describe tu experiencia con al menos 20 caracteres.';
    }

    if (texto.length > 500) {
      return 'La descripción no puede superar 500 caracteres.';
    }

    return null;
  }

  String? _validarZona(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe tu zona de servicio.';
    }

    if (texto.length > 100) {
      return 'La zona no puede superar 100 caracteres.';
    }

    return null;
  }

  String? _validarTarifa(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe tu tarifa por hora.';
    }

    final numero = double.tryParse(texto);

    if (numero == null) {
      return 'Escribe una tarifa válida.';
    }

    if (numero <= 0) {
      return 'La tarifa debe ser mayor a 0.';
    }

    if (numero > 100000) {
      return 'La tarifa es demasiado alta.';
    }

    return null;
  }

  String? _validarExperiencia(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe tus años de experiencia.';
    }

    final numero = int.tryParse(texto);

    if (numero == null) {
      return 'Escribe un número válido.';
    }

    if (numero < 0) {
      return 'La experiencia no puede ser negativa.';
    }

    if (numero > 80) {
      return 'La experiencia no puede superar 80 años.';
    }

    return null;
  }

  Future<void> _seleccionarImagen() async {
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
              borderRadius: BorderRadius.circular(28),
              boxShadow: _DogGoWeb.shadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _DogGoWeb.stroke,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Foto profesional',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(22),
                ),
                const SizedBox(height: 7),
                Text(
                  'Elige una foto clara para que los dueños te reconozcan.',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13),
                ),
                const SizedBox(height: 18),
                _BottomOption(
                  icon: Icons.photo_camera_rounded,
                  title: 'Tomar foto con cámara',
                  subtitle: 'Abrir cámara y tomar una foto nueva',
                  color: _DogGoWeb.teal,
                  surface: _DogGoWeb.tealLight,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _BottomOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir desde galería',
                  subtitle: 'Seleccionar una imagen del celular',
                  color: _DogGoWeb.purple,
                  surface: _DogGoWeb.purpleLight,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (_imagenSeleccionada != null) ...[
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
                        _imagenSeleccionada = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final imagen = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (imagen == null) return;

      setState(() {
        _imagenSeleccionada = File(imagen.path);
      });

      _mensaje(
        source == ImageSource.camera
            ? 'Foto tomada. Se subirá al guardar.'
            : 'Foto seleccionada. Se subirá al guardar.',
      );
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo seleccionar la imagen: $e');
    }
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      final tarifa = double.parse(_tarifaController.text.trim());
      final experiencia = int.parse(_experienciaController.text.trim());

      await PaseadoresService.guardarMiPerfilPaseador(
        descripcion: _descripcionController.text.trim(),
        zonaServicio: _zonaController.text.trim(),
        tarifaPorHora: tarifa,
        experienciaAnios: experiencia,
        disponible: _disponible,
      );

      if (_imagenSeleccionada != null) {
        await PaseadoresService.subirFotoMiPerfilPaseador(_imagenSeleccionada!);
      }

      if (!mounted) return;

      _mensaje('Perfil de paseador guardado correctamente.');

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');
      _mensaje('No se pudo guardar el perfil: $mensaje');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  bool get _tieneFoto {
    return _imagenSeleccionada != null || _fotoActualUrl != null;
  }

  bool get _perfilCompleto {
    final tieneDescripcion = _descripcionController.text.trim().isNotEmpty;
    final tieneZona = _zonaController.text.trim().isNotEmpty;
    final tieneTarifa =
        (double.tryParse(_tarifaController.text.trim()) ?? 0) > 0;
    final tieneExperiencia =
        int.tryParse(_experienciaController.text.trim()) != null;

    return tieneDescripcion &&
        tieneZona &&
        tieneTarifa &&
        tieneExperiencia &&
        _tieneFoto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DogGoWeb.cream,
      body: SafeArea(
        child: DogGoPatternBackground(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : Form(
                      key: _formKey,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildTopBar()),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(22, 28, 22, 34),
                              child: Column(
                                children: [
                                  _buildHero(),
                                  const SizedBox(height: 16),
                                  _buildEstadoPerfil(),
                                  const SizedBox(height: 16),
                                  _buildFotoCard(),
                                  const SizedBox(height: 16),
                                  _buildFormulario(),
                                  const SizedBox(height: 16),
                                  _buildDisponibilidad(),
                                  const SizedBox(height: 18),
                                  _buildBotones(),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: _FooterDogGo(),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
          IconButton(
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
          const DogGoLogo(size: 54),
          const Spacer(),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _guardando ? null : _cargarPerfilPaseador,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _DogGoWeb.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return DogGoPatternBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _DogGoWeb.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _DogGoWeb.stroke),
              boxShadow: _DogGoWeb.shadow(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: _DogGoWeb.rose,
                  size: 72,
                ),
                const SizedBox(height: 14),
                Text(
                  'No se pudo cargar el perfil',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(21),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? '',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _cargarPerfilPaseador,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DogGoWeb.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _DogGoWeb.purple,
                  _DogGoWeb.tealDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '👟 PERFIL PROFESIONAL',
                  style: _DogGoWeb.label(color: Colors.white),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 122,
                      height: 122,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildFotoPreview(),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            _perfilCompleto ? _DogGoWeb.green : _DogGoWeb.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _perfilCompleto
                            ? Icons.verified_rounded
                            : Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _perfilCompleto
                      ? 'Edita tu perfil de paseador'
                      : 'Completa tu perfil de paseador',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(
                    29,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Esta información se muestra a los dueños cuando buscan un paseador.',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(
                    13,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Text(
              'Agrega una foto clara, zona de servicio, tarifa y experiencia para que tu perfil se vea confiable.',
              textAlign: TextAlign.center,
              style: _DogGoWeb.subtitle(13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoPreview() {
    if (_imagenSeleccionada != null) {
      return Image.file(
        _imagenSeleccionada!,
        fit: BoxFit.cover,
      );
    }

    if (_fotoActualUrl != null &&
        (_fotoActualUrl!.startsWith('http://') ||
            _fotoActualUrl!.startsWith('https://'))) {
      return Image.network(
        _fotoActualUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.person_rounded,
            size: 58,
            color: Colors.white,
          );
        },
      );
    }

    return const Icon(
      Icons.person_rounded,
      size: 58,
      color: Colors.white,
    );
  }

  Widget _buildEstadoPerfil() {
    final completo = _perfilCompleto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: completo ? _DogGoWeb.greenLight : _DogGoWeb.orangeLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: completo
              ? _DogGoWeb.green.withOpacity(.22)
              : _DogGoWeb.orange.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completo ? _DogGoWeb.green : _DogGoWeb.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              completo ? Icons.verified_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completo ? 'Perfil listo' : 'Faltan datos por completar',
                  style: _DogGoWeb.title(18),
                ),
                const SizedBox(height: 5),
                Text(
                  completo
                      ? 'Tu perfil profesional ya tiene la información principal.'
                      : 'Agrega foto, descripción, zona, tarifa y experiencia.',
                  style: _DogGoWeb.subtitle(12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoCard() {
    return _SectionCard(
      title: 'Foto profesional',
      subtitle: 'Imagen visible para los dueños',
      icon: Icons.photo_camera_rounded,
      color: _DogGoWeb.purple,
      surface: _DogGoWeb.purpleLight,
      child: Row(
        children: [
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: _DogGoWeb.purpleLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _DogGoWeb.purple.withOpacity(.18),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _imagenSeleccionada != null
                  ? Image.file(
                      _imagenSeleccionada!,
                      fit: BoxFit.cover,
                    )
                  : _fotoActualUrl != null
                      ? Image.network(
                          _fotoActualUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Icon(
                              Icons.person_rounded,
                              color: _DogGoWeb.purple,
                              size: 44,
                            );
                          },
                        )
                      : const Icon(
                          Icons.person_rounded,
                          color: _DogGoWeb.purple,
                          size: 44,
                        ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tieneFoto ? 'Foto seleccionada' : 'Agrega una foto',
                  style: _DogGoWeb.body(
                    15,
                    color: _DogGoWeb.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Puedes tomarla con cámara o elegirla desde galería.',
                  style: _DogGoWeb.subtitle(12.5),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: _guardando ? null : _seleccionarImagen,
                    icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                    label: const Text('Cambiar foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DogGoWeb.teal,
                      side: const BorderSide(
                        color: _DogGoWeb.teal,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
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

  Widget _buildFormulario() {
    return _SectionCard(
      title: 'Datos profesionales',
      subtitle: 'Información visible para los dueños',
      icon: Icons.assignment_ind_rounded,
      color: _DogGoWeb.teal,
      surface: _DogGoWeb.tealLight,
      child: Column(
        children: [
          _CampoPerfil(
            controller: _descripcionController,
            label: 'Descripción',
            hint:
                'Ej. Paseador responsable con experiencia en perros medianos y grandes...',
            icon: Icons.description_rounded,
            color: _DogGoWeb.purple,
            surface: _DogGoWeb.purpleLight,
            maxLines: 4,
            validator: _validarDescripcion,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            controller: _zonaController,
            label: 'Zona de servicio',
            hint: 'Ej. Cumbres, San Jerónimo, Centro...',
            icon: Icons.location_on_rounded,
            color: _DogGoWeb.teal,
            surface: _DogGoWeb.tealLight,
            validator: _validarZona,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            controller: _tarifaController,
            label: 'Tarifa por hora',
            hint: 'Ej. 120',
            icon: Icons.attach_money_rounded,
            color: _DogGoWeb.green,
            surface: _DogGoWeb.greenLight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validarTarifa,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _CampoPerfil(
            controller: _experienciaController,
            label: 'Años de experiencia',
            hint: 'Ej. 2',
            icon: Icons.workspace_premium_rounded,
            color: _DogGoWeb.orange,
            surface: _DogGoWeb.orangeLight,
            keyboardType: TextInputType.number,
            validator: _validarExperiencia,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildDisponibilidad() {
    return _SectionCard(
      title: 'Disponibilidad',
      subtitle: 'Controla si apareces disponible',
      icon: Icons.check_circle_rounded,
      color: _disponible ? _DogGoWeb.green : _DogGoWeb.rose,
      surface: _disponible ? _DogGoWeb.greenLight : _DogGoWeb.roseLight,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _disponible ? _DogGoWeb.greenLight : _DogGoWeb.roseLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _disponible
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              color: _disponible ? _DogGoWeb.green : _DogGoWeb.rose,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _disponible ? 'Disponible para paseos' : 'Perfil pausado',
                  style: _DogGoWeb.body(
                    15,
                    color: _DogGoWeb.ink,
                    weight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _disponible
                      ? 'Tu perfil podrá aparecer como disponible.'
                      : 'Tu perfil quedará pausado temporalmente.',
                  style: _DogGoWeb.subtitle(12.5),
                ),
              ],
            ),
          ),
          Switch(
            value: _disponible,
            activeColor: _DogGoWeb.green,
            onChanged: _guardando
                ? null
                : (value) {
                    setState(() {
                      _disponible = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildBotones() {
    return Column(
      children: [
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
              _guardando ? 'Guardando...' : 'Guardar perfil profesional',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DogGoWeb.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _DogGoWeb.teal.withOpacity(.45),
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
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
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
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color surface;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.surface,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _DogGoWeb.card.withOpacity(.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _DogGoWeb.title(20),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: _DogGoWeb.subtitle(12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final Color surface;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;

  const _CampoPerfil({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    required this.surface,
    required this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
        filled: true,
        fillColor: _DogGoWeb.warm.withOpacity(.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
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
          borderSide: BorderSide(
            color: color,
            width: 1.4,
          ),
        ),
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
                  color: Colors.white.withOpacity(.82),
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

class _DogGoWeb {
  static const teal = Color(0xFF0F9B8E);
  static const tealDeep = Color(0xFF0D8A7E);
  static const tealLight = Color(0xFFE0F5F3);

  static const purple = Color(0xFF7156C8);
  static const purpleLight = Color(0xFFEDE7FA);

  static const orange = Color(0xFFF5A623);
  static const orangeLight = Color(0xFFFFF3DC);

  static const green = Color(0xFF22C55E);
  static const greenLight = Color(0xFFE5F8ED);

  static const rose = Color(0xFFEF4444);
  static const roseLight = Color(0xFFFEEEEE);

  static const cream = Color(0xFFFFFBF5);
  static const warm = Color(0xFFFFF6ED);
  static const card = Colors.white;
  static const ink = Color(0xFF2D3142);
  static const muted = Color(0xFF7B8194);
  static const stroke = Color(0xFFEDE8E0);

  static TextStyle title(
    double size, {
    Color color = ink,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -.6,
      height: 1.08,
    );
  }

  static TextStyle subtitle(
    double size, {
    Color color = muted,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle label({
    Color color = tealDeep,
  }) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: color,
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