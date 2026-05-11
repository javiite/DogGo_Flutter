import 'package:flutter/material.dart';
import '../services/calificaciones_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
class G {
  static const brand = Color(0xFF0D9E7E);
  static const brandDark = Color(0xFF0A7A62);
  static const clay = Color(0xFFD4694A);
  static const sage = Color(0xFF5B8C5A);
  static const gold = Color(0xFFCB9B3B);
  static const ink0 = Color(0xFFFAF7F2);
  static const ink1 = Color(0xFFF3EFE8);
  static const ink2 = Color(0xFFE8E2D9);
  static const ink3 = Color(0xFFC8C0B4);
  static const ink4 = Color(0xFF8C8278);
  static const ink5 = Color(0xFF4A4540);
  static const ink6 = Color(0xFF1E1A16);
  static const white = Color(0xFFFFFFFF);

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static const shadow1 = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static TextStyle h2(Color c) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: c,
    letterSpacing: -.4,
    height: 1.15,
  );
  static TextStyle h3(Color c) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: c,
    letterSpacing: -.2,
  );
  static TextStyle body(Color c, {double size = 13.5}) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w400, color: c);
  static TextStyle label(Color c, {double size = 12}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: c,
    letterSpacing: .3,
  );
}

class CalificarPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombrePaseador;

  const CalificarPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<CalificarPaseoScreen> createState() => _CalificarPaseoScreenState();
}

class _CalificarPaseoScreenState extends State<CalificarPaseoScreen> {
  final CalificacionesService _svc = CalificacionesService();
  final TextEditingController _ctrl = TextEditingController();
  int _puntaje = 5;
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final com = _ctrl.text.trim();
    if (_puntaje < 1 || _puntaje > 5) {
      _snack('Selecciona una calificación válida.');
      return;
    }
    if (com.length < 3) {
      _snack('Escribe un comentario más completo.');
      return;
    }

    setState(() => _enviando = true);

    try {
      final res = await _svc.calificarPaseo(
        paseoId: widget.paseoId,
        puntaje: _puntaje,
        comentario: com,
      );

      if (!mounted) return;

      // Verificamos si la respuesta del API fue exitosa (200 o 201)
      if (res['statusCode'] == 200 || res['statusCode'] == 201) {
        _snack('Calificación enviada ✅');

        // FIX: Usamos addPostFrameCallback para cerrar la pantalla de forma segura
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        });
      } else {
        _snack('Error: ${res['body']['message'] ?? 'No se pudo enviar'}');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('No se pudo enviar: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: G.body(G.white).copyWith(fontWeight: FontWeight.w600),
      ),
      backgroundColor: G.ink5,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: G.r12),
    ),
  );

  Color get _color => _puntaje <= 2
      ? G.clay
      : _puntaje == 3
      ? G.gold
      : _puntaje == 4
      ? G.brand
      : G.sage;
  String get _label =>
      ['', 'Muy malo', 'Malo', 'Regular', 'Bueno', 'Excelente'][_puntaje];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: G.ink0,
    appBar: AppBar(
      backgroundColor: G.ink0,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: G.ink6,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Calificar paseo', style: G.h2(G.ink6)),
      centerTitle: true,
    ),
    body: ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [G.brandDark, G.brand],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: G.r24,
            boxShadow: [
              BoxShadow(
                color: G.brand.withOpacity(.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: G.r16,
                  border: Border.all(color: Colors.white.withOpacity(.22)),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Cómo estuvo?', style: G.h2(Colors.white)),
                    const SizedBox(height: 5),
                    Text(
                      'Perro: ${widget.nombrePerro}',
                      style: G.label(Colors.white.withOpacity(.9)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Paseador: ${widget.nombrePaseador}',
                      style: G.body(Colors.white.withOpacity(.8), size: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Estrellas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: G.white,
            borderRadius: G.r20,
            boxShadow: G.shadow1,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(.12),
                      borderRadius: G.r12,
                    ),
                    child: Icon(Icons.reviews_rounded, color: _color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Calificación: $_label', style: G.h3(G.ink6)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  return GestureDetector(
                    onTap: _enviando
                        ? null
                        : () => setState(() => _puntaje = v),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        v <= _puntaje
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 44,
                        color: v <= _puntaje ? _color : G.ink2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text('$_puntaje de 5 estrellas', style: G.label(G.ink4)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comentario
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: G.white,
            borderRadius: G.r20,
            boxShadow: G.shadow1,
          ),
          child: TextField(
            controller: _ctrl,
            enabled: !_enviando,
            maxLines: 5,
            maxLength: 250,
            style: G.body(G.ink6),
            decoration: InputDecoration(
              labelText: 'Comentario',
              labelStyle: G.body(G.ink4),
              hintText: 'Ej. Fue puntual, cuidó muy bien a mi perro...',
              hintStyle: G.body(G.ink3),
              alignLabelWithHint: true,
              filled: true,
              fillColor: G.ink0,
              border: const OutlineInputBorder(
                borderRadius: G.r16,
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: G.r16,
                borderSide: BorderSide(color: G.brand, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Botón enviar
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _enviando ? 'Enviando...' : 'Enviar calificación',
              style: G.label(G.white).copyWith(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: G.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: G.ink2,
              shape: const RoundedRectangleBorder(borderRadius: G.r16),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Nota info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: G.ink1, borderRadius: G.r16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: G.ink4, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tu calificación ayuda a otros dueños a elegir paseadores confiables.',
                  style: G.body(G.ink5).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}
