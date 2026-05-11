import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../services/storage_service.dart';
import '../services/usuario_service.dart';
import '../widgets/doggo_logo.dart';
import '../widgets/doggo_map_preview.dart';
import '../widgets/doggo_pattern_background.dart';
import 'seleccionar_ubicacion_screen.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;

  const EditarPerfilScreen({
    super.key,
    required this.perfil,
  });

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;

  late final TextEditingController _direccionController;
  late final TextEditingController _referenciasController;
  late final TextEditingController _zonaController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _preferenciasController;

  bool _cargandoDuenio = false;
  bool _guardando = false;

  String? _baseUrl;
  String? _fotoActualUrl;
  File? _fotoSeleccionada;

  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: _texto(
        _valor(['nombre', 'Nombre', 'name', 'Name']),
        fallback: '',
      ),
    );

    _apellidoController = TextEditingController(
      text: _texto(
        _valor(['apellido', 'Apellido', 'lastName', 'LastName']),
        fallback: '',
      ),
    );

    _telefonoController = TextEditingController(
      text: _texto(
        _valor(['telefono', 'Telefono', 'phone', 'Phone']),
        fallback: '',
      ),
    );

    _direccionController = TextEditingController();
    _referenciasController = TextEditingController();
    _zonaController = TextEditingController();
    _descripcionController = TextEditingController();
    _preferenciasController = TextEditingController();

    _inicializar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();

    _direccionController.dispose();
    _referenciasController.dispose();
    _zonaController.dispose();
    _descripcionController.dispose();
    _preferenciasController.dispose();

    super.dispose();
  }

  Future<void> _inicializar() async {
    final baseUrl = await StorageService.obtenerBaseUrl();

    if (!mounted) return;

    setState(() {
      _baseUrl = baseUrl;
    });

    if (_mostrarPerfilDuenio) {
      await _cargarPerfilDuenio();
    }
  }

  Future<void> _cargarPerfilDuenio() async {
    setState(() {
      _cargandoDuenio = true;
    });

    try {
      final perfilDuenio = await _usuarioService.obtenerPerfilDuenio();

      if (!mounted) return;

      final foto = perfilDuenio['fotoUrl'] ??
          perfilDuenio['FotoUrl'] ??
          perfilDuenio['imagenUrl'] ??
          perfilDuenio['ImagenUrl'];

      _direccionController.text = _texto(
        perfilDuenio['direccion'] ?? perfilDuenio['Direccion'],
        fallback: '',
      );

      _referenciasController.text = _texto(
        perfilDuenio['referenciasDireccion'] ??
            perfilDuenio['ReferenciasDireccion'] ??
            perfilDuenio['referencias'] ??
            perfilDuenio['Referencias'],
        fallback: '',
      );

      _zonaController.text = _texto(
        perfilDuenio['zona'] ?? perfilDuenio['Zona'],
        fallback: '',
      );

      _descripcionController.text = _texto(
        perfilDuenio['descripcion'] ?? perfilDuenio['Descripcion'],
        fallback: '',
      );

      _preferenciasController.text = _texto(
        perfilDuenio['preferenciasPaseo'] ??
            perfilDuenio['PreferenciasPaseo'],
        fallback: '',
      );

      _latitud = _doubleSeguro(
        perfilDuenio['latitud'] ?? perfilDuenio['Latitud'],
      );

      _longitud = _doubleSeguro(
        perfilDuenio['longitud'] ?? perfilDuenio['Longitud'],
      );

      setState(() {
        _fotoActualUrl = _urlPublica(foto);
        _cargandoDuenio = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargandoDuenio = false;
      });
    }
  }

  dynamic _valor(List<String> keys) {
    for (final key in keys) {
      if (widget.perfil.containsKey(key) && widget.perfil[key] != null) {
        return widget.perfil[key];
      }
    }

    return null;
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  double? _doubleSeguro(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();

    return double.tryParse(valor.toString());
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

  String get _email {
    return _texto(
      _valor(['email', 'Email', 'correo', 'Correo']),
      fallback: 'Correo no disponible',
    );
  }

  String get _rol {
    final rol = _texto(
      _valor(['rol', 'Rol', 'role', 'Role']),
      fallback: 'Usuario',
    );

    final normalizado = rol.toLowerCase();

    if (normalizado.contains('paseador')) return 'Paseador';

    if (normalizado.contains('dueño') ||
        normalizado.contains('duenio') ||
        normalizado.contains('dueno') ||
        normalizado.contains('cliente') ||
        normalizado.contains('owner')) {
      return 'Dueño';
    }

    if (normalizado.contains('admin')) return 'Administrador';

    return rol;
  }

  bool get _esPaseador {
    return _rol.toLowerCase().trim().contains('paseador');
  }

  bool get _mostrarPerfilDuenio {
    return !_esPaseador;
  }

  String get _nombreCompleto {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final completo = '$nombre $apellido'.trim();

    return completo.isEmpty ? 'Usuario DogGo' : completo;
  }

  String? _validarNombre(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) return 'El nombre es obligatorio.';
    if (texto.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    if (texto.length > 80) return 'El nombre es demasiado largo.';

    return null;
  }

  String? _validarApellido(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) return 'El apellido es obligatorio.';
    if (texto.length < 2) return 'El apellido debe tener al menos 2 caracteres.';
    if (texto.length > 80) return 'El apellido es demasiado largo.';

    return null;
  }

  String? _validarTelefono(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) return 'El teléfono es obligatorio.';
    if (texto.length < 8) return 'El teléfono es demasiado corto.';
    if (texto.length > 20) return 'El teléfono es demasiado largo.';

    return null;
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _seleccionarFoto() async {
    if (_guardando) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: _DogGoWeb.card,
              borderRadius: BorderRadius.circular(28),
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
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Actualizar foto',
                  style: _DogGoWeb.title(22),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige una foto clara para tu perfil.',
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(13),
                ),
                const SizedBox(height: 18),
                _BottomSheetOption(
                  icon: Icons.photo_camera_rounded,
                  title: 'Tomar foto',
                  subtitle: 'Abrir cámara del celular',
                  color: _DogGoWeb.teal,
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _BottomSheetOption(
                  icon: Icons.photo_library_rounded,
                  title: 'Elegir de galería',
                  subtitle: 'Seleccionar una imagen guardada',
                  color: _DogGoWeb.purple,
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                if (_fotoSeleccionada != null) ...[
                  const SizedBox(height: 10),
                  _BottomSheetOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Quitar selección',
                    subtitle: 'Mantener la foto actual',
                    color: _DogGoWeb.rose,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _fotoSeleccionada = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  width: double.infinity,
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
        _fotoSeleccionada = File(imagen.path);
      });

      _mensaje('Foto seleccionada. Se subirá al guardar.');
    } catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo seleccionar la foto: $e');
    }
  }

  Future<void> _seleccionarUbicacion() async {
    final resultado = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionarUbicacionScreen(
          ubicacionInicial: _latitud != null && _longitud != null
              ? LatLng(_latitud!, _longitud!)
              : null,
          textoInicial: _direccionController.text.trim().isNotEmpty
              ? _direccionController.text.trim()
              : null,
        ),
      ),
    );

    if (resultado == null) return;

    final lat = _doubleSeguro(resultado['latitud']);
    final lng = _doubleSeguro(resultado['longitud']);
    final texto = resultado['texto'] ??
        resultado['ubicacionTexto'] ??
        resultado['direccionRecogida'];

    setState(() {
      _latitud = lat;
      _longitud = lng;

      if (texto != null && texto.toString().trim().isNotEmpty) {
        _direccionController.text = texto.toString().trim();
      }
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _usuarioService.actualizarPerfil(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        telefono: _telefonoController.text.trim(),
      );

      if (_mostrarPerfilDuenio) {
        if (_fotoSeleccionada != null) {
          await _usuarioService.subirFotoPerfilDuenio(_fotoSeleccionada!);
        }

        await _usuarioService.actualizarPerfilDuenio(
          direccion: _direccionController.text.trim(),
          referenciasDireccion: _referenciasController.text.trim(),
          zona: _zonaController.text.trim(),
          latitud: _latitud,
          longitud: _longitud,
          descripcion: _descripcionController.text.trim(),
          preferenciasPaseo: _preferenciasController.text.trim(),
        );
      }

      if (!mounted) return;

      _mensaje('Perfil actualizado correctamente.');

      await Future.delayed(const Duration(milliseconds: 550));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');
      _mensaje('No se pudo actualizar el perfil: $mensaje');
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Widget _fotoWidget() {
    if (_fotoSeleccionada != null) {
      return Image.file(
        _fotoSeleccionada!,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DogGoWeb.cream,
      body: SafeArea(
        child: DogGoPatternBackground(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildTopBar()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                    child: Column(
                      children: [
                        _buildHero(),
                        const SizedBox(height: 18),
                        _buildFormCard(),
                        const SizedBox(height: 16),
                        _buildFooterActions(),
                        const SizedBox(height: 22),
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
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.93),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(.06),
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
          const DogGoLogo(size: 52),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _DogGoWeb.tealLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Editar',
              style: _DogGoWeb.body(
                11.5,
                color: _DogGoWeb.tealDeep,
                weight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _DogGoWeb.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _DogGoWeb.teal,
                  _DogGoWeb.tealDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'EDITAR PERFIL',
                  style: _DogGoWeb.label(color: Colors.white),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: _mostrarPerfilDuenio ? _seleccionarFoto : null,
                      child: Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _mostrarPerfilDuenio
                            ? _fotoWidget()
                            : const Icon(
                                Icons.manage_accounts_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    if (_mostrarPerfilDuenio)
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _DogGoWeb.orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _nombreCompleto,
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.title(
                    30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: _DogGoWeb.subtitle(
                    13,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(.28),
                    ),
                  ),
                  child: Text(
                    _rol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Text(
              _mostrarPerfilDuenio
                  ? 'Actualiza tu información de contacto, ubicación y preferencias de paseo.'
                  : 'Actualiza tu información personal de la cuenta.',
              textAlign: TextAlign.center,
              style: _DogGoWeb.subtitle(13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DogGoWeb.card.withOpacity(.97),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _DogGoWeb.stroke),
        boxShadow: _DogGoWeb.shadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del perfil',
            style: _DogGoWeb.title(23),
          ),
          const SizedBox(height: 5),
          Text(
            'Mantén estos datos actualizados para coordinar mejor los paseos.',
            style: _DogGoWeb.subtitle(13),
          ),
          const SizedBox(height: 20),
          _SectionHeaderClean(
            icon: Icons.person_rounded,
            title: 'Datos personales',
            color: _DogGoWeb.teal,
          ),
          const SizedBox(height: 14),
          _CleanTextField(
            controller: _nombreController,
            label: 'Nombre',
            hint: 'Ej. Javier',
            icon: Icons.person_outline_rounded,
            validator: _validarNombre,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _CleanTextField(
            controller: _apellidoController,
            label: 'Apellido',
            hint: 'Ej. Terrones',
            icon: Icons.badge_outlined,
            validator: _validarApellido,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _CleanTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            hint: 'Ej. 8112345678',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _validarTelefono,
          ),
          const SizedBox(height: 16),
          _ReadOnlyStrip(
            title: 'Correo',
            value: _email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 10),
          _ReadOnlyStrip(
            title: 'Rol',
            value: _rol,
            icon: Icons.verified_user_outlined,
          ),
          if (_mostrarPerfilDuenio) ...[
            const SizedBox(height: 24),
            _SectionHeaderClean(
              icon: Icons.pets_rounded,
              title: 'Perfil de dueño',
              color: _DogGoWeb.orange,
            ),
            const SizedBox(height: 14),
            _PhotoInlineCard(
              fotoActualUrl: _fotoActualUrl,
              fotoSeleccionada: _fotoSeleccionada,
              cargando: _cargandoDuenio,
              onTap: _seleccionarFoto,
            ),
            const SizedBox(height: 14),
            _CleanTextField(
              controller: _direccionController,
              label: 'Dirección predeterminada',
              hint: 'Ej. Av. Leones 123, Cumbres',
              icon: Icons.home_rounded,
              validator: (_) => null,
            ),
            const SizedBox(height: 12),
            _CleanTextField(
              controller: _referenciasController,
              label: 'Referencias',
              hint: 'Ej. Portón negro, frente al Oxxo',
              icon: Icons.notes_rounded,
              validator: (_) => null,
            ),
            const SizedBox(height: 12),
            _CleanTextField(
              controller: _zonaController,
              label: 'Zona',
              hint: 'Ej. Centro, Cumbres, San Pedro',
              icon: Icons.location_on_rounded,
              validator: (_) => null,
            ),
            const SizedBox(height: 18),
            _SectionHeaderClean(
              icon: Icons.map_rounded,
              title: 'Ubicación en mapa',
              color: _DogGoWeb.teal,
              small: true,
            ),
            const SizedBox(height: 9),
            Text(
              'Selecciona el punto donde normalmente se realizará la recolección.',
              style: _DogGoWeb.subtitle(12.5),
            ),
            const SizedBox(height: 12),
            DogGoMapPreview(
              latitud: _latitud,
              longitud: _longitud,
              height: 220,
              emptyText: 'Selecciona tu ubicación predeterminada',
              onTap: _seleccionarUbicacion,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _seleccionarUbicacion,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text('Seleccionar ubicación'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DogGoWeb.teal,
                  backgroundColor: _DogGoWeb.tealLight.withOpacity(.55),
                  side: BorderSide(
                    color: _DogGoWeb.teal.withOpacity(.24),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _CleanTextField(
              controller: _descripcionController,
              label: 'Descripción',
              hint: 'Ej. Tengo 2 perros tranquilos...',
              icon: Icons.description_rounded,
              validator: (_) => null,
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _CleanTextField(
              controller: _preferenciasController,
              label: 'Preferencias de paseo',
              hint: 'Ej. Evitar avenidas grandes...',
              icon: Icons.checklist_rounded,
              validator: (_) => null,
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 19),
            label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
            style: FilledButton.styleFrom(
              backgroundColor: _DogGoWeb.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _DogGoWeb.teal.withOpacity(.45),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DogGoWeb.muted,
              backgroundColor: Colors.white.withOpacity(.65),
              side: const BorderSide(color: _DogGoWeb.stroke),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(23),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            child: const Text('Cancelar'),
          ),
        ),
      ],
    );
  }
}

class _PhotoInlineCard extends StatelessWidget {
  final String? fotoActualUrl;
  final File? fotoSeleccionada;
  final bool cargando;
  final VoidCallback onTap;

  const _PhotoInlineCard({
    required this.fotoActualUrl,
    required this.fotoSeleccionada,
    required this.cargando,
    required this.onTap,
  });

  bool get _tieneFotoActual {
    return fotoActualUrl != null &&
        (fotoActualUrl!.startsWith('http://') ||
            fotoActualUrl!.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (cargando) {
      image = const Center(child: CircularProgressIndicator(strokeWidth: 2));
    } else if (fotoSeleccionada != null) {
      image = Image.file(
        fotoSeleccionada!,
        fit: BoxFit.cover,
      );
    } else if (_tieneFotoActual) {
      image = Image.network(
        fotoActualUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.person_rounded,
            color: _DogGoWeb.teal,
            size: 42,
          );
        },
      );
    } else {
      image = const Icon(
        Icons.person_rounded,
        color: _DogGoWeb.teal,
        size: 42,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _DogGoWeb.warm.withOpacity(.74),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _DogGoWeb.stroke.withOpacity(.9),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _DogGoWeb.tealLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _DogGoWeb.teal.withOpacity(.16),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: image,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fotoSeleccionada != null || _tieneFotoActual
                        ? 'Foto de perfil'
                        : 'Agrega una foto',
                    style: _DogGoWeb.body(
                      14.5,
                      color: _DogGoWeb.ink,
                      weight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Toca para tomar foto o elegir desde galería.',
                    style: _DogGoWeb.subtitle(12.3),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _DogGoWeb.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderClean extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool small;

  const _SectionHeaderClean({
    required this.icon,
    required this.title,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: small ? 32 : 36,
          height: small ? 32 : 36,
          decoration: BoxDecoration(
            color: color.withOpacity(.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: small ? 18 : 20,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: _DogGoWeb.body(
            small ? 14.5 : 16,
            color: _DogGoWeb.ink,
            weight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  const _CleanTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: _DogGoWeb.body(
        14,
        color: _DogGoWeb.ink,
        weight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(11),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _DogGoWeb.tealLight.withOpacity(.75),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _DogGoWeb.teal,
              size: 18,
            ),
          ),
        ),
        filled: true,
        fillColor: _DogGoWeb.warm.withOpacity(.68),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        labelStyle: _DogGoWeb.subtitle(13),
        hintStyle: _DogGoWeb.subtitle(12.5),
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
    );
  }
}

class _ReadOnlyStrip extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReadOnlyStrip({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _DogGoWeb.stroke.withOpacity(.9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _DogGoWeb.muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: _DogGoWeb.subtitle(12.5),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: _DogGoWeb.body(
                13,
                color: _DogGoWeb.ink,
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(.10),
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
      color: _DogGoWeb.tealLight.withOpacity(.42),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
      child: Column(
        children: [
          const DogGoLogo(size: 40),
          const SizedBox(height: 10),
          Text(
            'DogGo © 2026 — Proyecto universitario',
            style: _DogGoWeb.subtitle(12.5),
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
      letterSpacing: -.45,
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
      fontSize: 11.5,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: 1.5,
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
        color: Colors.black.withOpacity(.055),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}