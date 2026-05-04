import 'package:flutter/material.dart';

import '../services/usuario_service.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);
  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);
  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);
  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);

  static List<BoxShadow> shadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 16,
        offset: const Offset(0, 5),
      ),
    ];
  }
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

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

  late final TextEditingController _nombreController;
  late final TextEditingController _apellidoController;
  late final TextEditingController _telefonoController;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: _texto(
        widget.perfil['nombre'] ?? widget.perfil['Nombre'],
        fallback: '',
      ),
    );

    _apellidoController = TextEditingController(
      text: _texto(
        widget.perfil['apellido'] ?? widget.perfil['Apellido'],
        fallback: '',
      ),
    );

    _telefonoController = TextEditingController(
      text: _texto(
        widget.perfil['telefono'] ?? widget.perfil['Telefono'],
        fallback: '',
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') {
      return fallback;
    }

    return texto;
  }

  String get _email {
    return _texto(
      widget.perfil['email'] ?? widget.perfil['Email'],
      fallback: 'Correo no disponible',
    );
  }

  String get _rol {
    return _texto(
      widget.perfil['rol'] ?? widget.perfil['Rol'],
      fallback: 'Rol no disponible',
    );
  }

  String? _validarTexto(String? valor, String campo) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return '$campo es obligatorio.';
    }

    if (texto.length < 2) {
      return '$campo debe tener al menos 2 caracteres.';
    }

    return null;
  }

  String? _validarTelefono(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'El teléfono es obligatorio.';
    }

    if (texto.length < 8) {
      return 'El teléfono es demasiado corto.';
    }

    return null;
  }

  Future<void> _guardar() async {
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el perfil: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
                child: Text('✏️', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Editar perfil',
              style: _ts(20, FontWeight.w900, Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFormulario(),
            const SizedBox(height: 18),
            _buildBotonGuardar(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EC9A0),
            Color(0xFF057A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.22)),
            ),
            child: const Icon(
              Icons.manage_accounts_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualiza tus datos',
                  style: _ts(19, FontWeight.w900, Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: _ts(
                    13,
                    FontWeight.w500,
                    Colors.white.withOpacity(.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rol: $_rol',
                  style: _ts(
                    12,
                    FontWeight.w700,
                    Colors.white.withOpacity(.85),
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
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _T.shadow(),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _CampoPerfil(
              controller: _nombreController,
              label: 'Nombre',
              icono: Icons.person_rounded,
              color: _T.teal,
              surface: _T.tealSurface,
              validator: (valor) => _validarTexto(valor, 'El nombre'),
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              controller: _apellidoController,
              label: 'Apellido',
              icono: Icons.person_outline_rounded,
              color: _T.violet,
              surface: _T.violetSurf,
              validator: (valor) => _validarTexto(valor, 'El apellido'),
            ),
            const SizedBox(height: 14),
            _CampoPerfil(
              controller: _telefonoController,
              label: 'Teléfono',
              icono: Icons.phone_rounded,
              color: _T.emerald,
              surface: _T.emeraldSurf,
              keyboardType: TextInputType.phone,
              validator: _validarTelefono,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
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
        label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _CampoPerfil extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final Color color;
  final Color surface;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CampoPerfil({
    required this.controller,
    required this.label,
    required this.icono,
    required this.color,
    required this.surface,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
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
              icono,
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
      ),
    );
  }
}