import 'package:flutter/material.dart';

import '../services/usuario_service.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);

  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);

  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);

  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEEEEE);

  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.055),
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

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final UsuarioService _usuarioService = UsuarioService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _actualController = TextEditingController();
  final TextEditingController _nuevaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  bool _guardando = false;
  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirmar = false;

  @override
  void initState() {
    super.initState();
    _nuevaController.addListener(_actualizar);
    _confirmarController.addListener(_actualizar);
  }

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  String get _actual => _actualController.text.trim();
  String get _nueva => _nuevaController.text.trim();
  String get _confirmar => _confirmarController.text.trim();

  bool get _largoOk => _nueva.length >= 6;
  bool get _diferenteOk => _nueva.isNotEmpty && _nueva != _actual;
  bool get _coincidenOk => _nueva.isNotEmpty && _nueva == _confirmar;
  bool get _tieneNumero => RegExp(r'\d').hasMatch(_nueva);
  bool get _tieneLetra => RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(_nueva);

  int get _puntaje {
    var puntos = 0;

    if (_largoOk) puntos++;
    if (_diferenteOk) puntos++;
    if (_coincidenOk) puntos++;
    if (_tieneNumero) puntos++;
    if (_tieneLetra) puntos++;

    return puntos;
  }

  String get _nivelTexto {
    if (_nueva.isEmpty) return 'Sin evaluar';
    if (_puntaje <= 2) return 'Débil';
    if (_puntaje <= 4) return 'Aceptable';
    return 'Segura';
  }

  Color get _nivelColor {
    if (_nueva.isEmpty) return _T.inkSub;
    if (_puntaje <= 2) return _T.rose;
    if (_puntaje <= 4) return _T.amber;
    return _T.emerald;
  }

  Color get _nivelSurface {
    if (_nueva.isEmpty) return const Color(0xFFF3F4F6);
    if (_puntaje <= 2) return _T.roseSurf;
    if (_puntaje <= 4) return _T.amberSurf;
    return _T.emeraldSurf;
  }

  String? _validarActual(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe tu contraseña actual.';
    }

    return null;
  }

  String? _validarNueva(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Escribe la nueva contraseña.';
    }

    if (texto.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    if (texto == _actualController.text.trim()) {
      return 'La nueva contraseña debe ser diferente.';
    }

    return null;
  }

  String? _validarConfirmacion(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Confirma la nueva contraseña.';
    }

    if (texto != _nuevaController.text.trim()) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
    });

    try {
      await _usuarioService.cambiarPassword(
        passwordActual: _actualController.text.trim(),
        passwordNueva: _nuevaController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cambiar la contraseña: $mensaje'),
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
                child: Text('🔐', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Cambiar contraseña',
              style: _ts(20, FontWeight.w900, Colors.white),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFormulario(),
            const SizedBox(height: 14),
            _buildSeguridadCard(),
            const SizedBox(height: 18),
            _buildBoton(),
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
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0EC9A0),
            Color(0xFF057A5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _T.teal.withOpacity(.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
              Icons.lock_reset_rounded,
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
                  'Seguridad de la cuenta',
                  style: _ts(20, FontWeight.w900, Colors.white),
                ),
                const SizedBox(height: 5),
                Text(
                  'Cambia tu contraseña usando tu clave actual.',
                  style: _ts(
                    13,
                    FontWeight.w600,
                    Colors.white.withOpacity(.88),
                    height: 1.3,
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
            _CampoPassword(
              controller: _actualController,
              label: 'Contraseña actual',
              visible: _verActual,
              color: _T.teal,
              surface: _T.tealSurface,
              onToggleVisible: () {
                setState(() {
                  _verActual = !_verActual;
                });
              },
              validator: _validarActual,
            ),
            const SizedBox(height: 14),
            _CampoPassword(
              controller: _nuevaController,
              label: 'Nueva contraseña',
              visible: _verNueva,
              color: _T.teal,
              surface: _T.tealSurface,
              onToggleVisible: () {
                setState(() {
                  _verNueva = !_verNueva;
                });
              },
              validator: _validarNueva,
            ),
            const SizedBox(height: 14),
            _CampoPassword(
              controller: _confirmarController,
              label: 'Confirmar nueva contraseña',
              visible: _verConfirmar,
              color: _T.teal,
              surface: _T.tealSurface,
              onToggleVisible: () {
                setState(() {
                  _verConfirmar = !_verConfirmar;
                });
              },
              validator: _validarConfirmacion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeguridadCard() {
    final progress = (_puntaje / 5).clamp(0.0, 1.0);

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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _nivelSurface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: _nivelColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel de seguridad',
                      style: _ts(15, FontWeight.w900, _T.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _nivelTexto,
                      style: _ts(12.5, FontWeight.w800, _nivelColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFF3F4F6),
              color: _nivelColor,
            ),
          ),
          const SizedBox(height: 14),
          _ReglaPassword(
            texto: 'Mínimo 6 caracteres',
            completa: _largoOk,
          ),
          _ReglaPassword(
            texto: 'Diferente a la contraseña actual',
            completa: _diferenteOk,
          ),
          _ReglaPassword(
            texto: 'Confirmación coincide',
            completa: _coincidenOk,
          ),
          _ReglaPassword(
            texto: 'Incluye letras',
            completa: _tieneLetra,
          ),
          _ReglaPassword(
            texto: 'Incluye números',
            completa: _tieneNumero,
          ),
        ],
      ),
    );
  }

  Widget _buildBoton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
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
        label: Text(_guardando ? 'Actualizando...' : 'Actualizar contraseña'),
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

  Widget _buildNota() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.amberSurf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _T.amber.withOpacity(.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: _T.amber,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Después de cambiar tu contraseña, úsala en tu siguiente inicio de sesión.',
              style: _ts(
                12.5,
                FontWeight.w700,
                _T.inkSub,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampoPassword extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final Color color;
  final Color surface;
  final VoidCallback onToggleVisible;
  final String? Function(String?)? validator;

  const _CampoPassword({
    required this.controller,
    required this.label,
    required this.visible,
    required this.color,
    required this.surface,
    required this.onToggleVisible,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
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
              Icons.lock_rounded,
              color: color,
              size: 20,
            ),
          ),
        ),
        suffixIcon: IconButton(
          onPressed: onToggleVisible,
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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

class _ReglaPassword extends StatelessWidget {
  final String texto;
  final bool completa;

  const _ReglaPassword({
    required this.texto,
    required this.completa,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            completa ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: completa ? _T.emerald : _T.inkSub,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: _ts(
                12.5,
                FontWeight.w700,
                completa ? _T.ink : _T.inkSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}