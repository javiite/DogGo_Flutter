import 'dart:math';
import 'package:flutter/material.dart';

class MapaPaseoScreen extends StatelessWidget {
  final Map<String, dynamic> paseo;

  const MapaPaseoScreen({
    super.key,
    required this.paseo,
  });

  String _texto(dynamic valor, {String fallback = 'No disponible'}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    return texto.isEmpty ? fallback : texto;
  }

  double? _double(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    return double.tryParse(valor.toString());
  }

  String get estado => _texto(paseo['estado'], fallback: 'Pendiente');

  bool get estaEnCurso => estado.toLowerCase() == 'encurso';

  bool get estaFinalizado => estado.toLowerCase() == 'finalizado';

  bool get estaCancelado => estado.toLowerCase() == 'cancelado';

  Color get colorEstado {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'aceptado':
        return Colors.blue;
      case 'encurso':
        return Colors.green;
      case 'finalizado':
        return Colors.purple;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombrePerro = _texto(
      paseo['perroNombre'] ??
          paseo['nombrePerro'] ??
          paseo['perro']?['nombre'],
      fallback: 'Perro',
    );

    final nombrePaseador = _texto(
      paseo['paseadorNombre'] ??
          paseo['nombrePaseador'] ??
          paseo['paseador']?['usuario']?['nombre'],
      fallback: 'Paseador',
    );

    final latActual = _double(
      paseo['latitudActual'] ??
          paseo['LatitudActual'] ??
          paseo['ubicacionActual']?['latitud'],
    );

    final lngActual = _double(
      paseo['longitudActual'] ??
          paseo['LongitudActual'] ??
          paseo['ubicacionActual']?['longitud'],
    );

    final latRecogida = _double(
      paseo['latitudRecogida'] ?? paseo['LatitudRecogida'],
    );

    final lngRecogida = _double(
      paseo['longitudRecogida'] ?? paseo['LongitudRecogida'],
    );

    final ubicacionTexto = _texto(
      paseo['ubicacionTexto'] ??
          paseo['direccionRecogida'] ??
          paseo['ubicacionRecogidaTexto'],
      fallback: 'Ubicación de recogida no definida',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Mapa del paseo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderPaseo(
              nombrePerro: nombrePerro,
              nombrePaseador: nombrePaseador,
              estado: estado,
              colorEstado: colorEstado,
            ),
            const SizedBox(height: 16),

            _MapaVisualCard(
              estado: estado,
              colorEstado: colorEstado,
              latActual: latActual,
              lngActual: lngActual,
              latRecogida: latRecogida,
              lngRecogida: lngRecogida,
            ),

            const SizedBox(height: 16),

            _InfoUbicacionCard(
              titulo: 'Punto de recogida',
              icono: Icons.home_rounded,
              contenido: ubicacionTexto,
              latitud: latRecogida,
              longitud: lngRecogida,
            ),

            const SizedBox(height: 12),

            _InfoUbicacionCard(
              titulo: estaFinalizado
                  ? 'Última ubicación registrada'
                  : 'Ubicación actual del paseo',
              icono: estaEnCurso
                  ? Icons.my_location_rounded
                  : Icons.location_on_rounded,
              contenido: latActual != null && lngActual != null
                  ? 'Coordenadas registradas por el paseador'
                  : 'Todavía no hay ubicación actual disponible',
              latitud: latActual,
              longitud: lngActual,
            ),

            const SizedBox(height: 16),

            _TrackingTimeline(
              estado: estado,
              colorEstado: colorEstado,
            ),

            const SizedBox(height: 16),

            _BotonesMapa(
              tieneUbicacionActual: latActual != null && lngActual != null,
              latActual: latActual,
              lngActual: lngActual,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPaseo extends StatelessWidget {
  final String nombrePerro;
  final String nombrePaseador;
  final String estado;
  final Color colorEstado;

  const _HeaderPaseo({
    required this.nombrePerro,
    required this.nombrePaseador,
    required this.estado,
    required this.colorEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF1F8A70).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Color(0xFF1F8A70),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombrePerro,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Paseador: $nombrePaseador',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: colorEstado,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapaVisualCard extends StatelessWidget {
  final String estado;
  final Color colorEstado;
  final double? latActual;
  final double? lngActual;
  final double? latRecogida;
  final double? lngRecogida;

  const _MapaVisualCard({
    required this.estado,
    required this.colorEstado,
    required this.latActual,
    required this.lngActual,
    required this.latRecogida,
    required this.lngRecogida,
  });

  @override
  Widget build(BuildContext context) {
    final tieneTracking = latActual != null && lngActual != null;

    return Container(
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _MapaPainter(
                  tieneTracking: tieneTracking,
                  colorEstado: colorEstado,
                ),
              ),
            ),

            Positioned(
              left: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Icon(
                      tieneTracking
                          ? Icons.navigation_rounded
                          : Icons.location_searching_rounded,
                      color: colorEstado,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tieneTracking
                          ? 'Tracking visual activo'
                          : 'Esperando ubicación',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              right: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  estado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            Positioned(
              left: 24,
              bottom: 24,
              child: _PuntoMapa(
                titulo: 'Recogida',
                subtitulo: latRecogida != null && lngRecogida != null
                    ? 'Ubicación guardada'
                    : 'No definida',
                icono: Icons.home_rounded,
                color: Colors.blue,
              ),
            ),

            Positioned(
              right: 24,
              bottom: 88,
              child: _PuntoMapa(
                titulo: 'Paseador',
                subtitulo: tieneTracking ? 'Última señal GPS' : 'Sin señal',
                icono: Icons.directions_walk_rounded,
                color: colorEstado,
              ),
            ),

            Positioned(
              right: 24,
              bottom: 24,
              child: _PuntoMapa(
                titulo: 'Ruta',
                subtitulo: tieneTracking ? 'En progreso' : 'Pendiente',
                icono: Icons.route_rounded,
                color: Colors.deepOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapaPainter extends CustomPainter {
  final bool tieneTracking;
  final Color colorEstado;

  _MapaPainter({
    required this.tieneTracking,
    required this.colorEstado,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fondo = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE8F5E9),
          Color(0xFFE3F2FD),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fondo);

    final callePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final calleBordePaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-20, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.10,
        size.width * 0.65,
        size.height * 0.30,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.47,
        size.width + 20,
        size.height * 0.37,
      );

    final path2 = Path()
      ..moveTo(size.width * 0.15, size.height + 20)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.46,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.18,
        size.width * 0.92,
        -20,
      );

    final path3 = Path()
      ..moveTo(-20, size.height * 0.75)
      ..lineTo(size.width + 20, size.height * 0.58);

    canvas.drawPath(path1, calleBordePaint);
    canvas.drawPath(path1, callePaint);

    canvas.drawPath(path2, calleBordePaint);
    canvas.drawPath(path2, callePaint);

    canvas.drawPath(path3, calleBordePaint);
    canvas.drawPath(path3, callePaint);

    final rutaPaint = Paint()
      ..color = tieneTracking ? colorEstado : Colors.grey
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ruta = Path()
      ..moveTo(size.width * 0.18, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.58,
        size.width * 0.48,
        size.height * 0.54,
      )
      ..quadraticBezierTo(
        size.width * 0.67,
        size.height * 0.49,
        size.width * 0.80,
        size.height * 0.30,
      );

    canvas.drawPath(ruta, rutaPaint);

    final puntosPaint = Paint()
      ..color = tieneTracking ? colorEstado : Colors.grey;

    for (double i = 0; i <= 1; i += 0.15) {
      final x = lerpDouble(size.width * 0.18, size.width * 0.80, i);
      final y = size.height * (0.72 - sin(i * pi) * 0.25 - i * 0.35);
      canvas.drawCircle(Offset(x, y), 3, puntosPaint);
    }
  }

  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(covariant _MapaPainter oldDelegate) {
    return oldDelegate.tieneTracking != tieneTracking ||
        oldDelegate.colorEstado != colorEstado;
  }
}

class _PuntoMapa extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;

  const _PuntoMapa({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
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

class _InfoUbicacionCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final String contenido;
  final double? latitud;
  final double? longitud;

  const _InfoUbicacionCard({
    required this.titulo,
    required this.icono,
    required this.contenido,
    required this.latitud,
    required this.longitud,
  });

  @override
  Widget build(BuildContext context) {
    final tieneCoordenadas = latitud != null && longitud != null;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1F8A70).withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icono,
              color: const Color(0xFF1F8A70),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  contenido,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                if (tieneCoordenadas)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lat: ${latitud!.toStringAsFixed(6)}  •  Lng: ${longitud!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
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

class _TrackingTimeline extends StatelessWidget {
  final String estado;
  final Color colorEstado;

  const _TrackingTimeline({
    required this.estado,
    required this.colorEstado,
  });

  int get pasoActual {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 0;
      case 'aceptado':
        return 1;
      case 'encurso':
        return 2;
      case 'finalizado':
        return 3;
      case 'cancelado':
        return 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = [
      _PasoTracking(
        titulo: 'Solicitado',
        subtitulo: 'El paseo fue creado',
        icono: Icons.assignment_rounded,
      ),
      _PasoTracking(
        titulo: 'Aceptado',
        subtitulo: 'El paseador confirmó',
        icono: Icons.check_circle_rounded,
      ),
      _PasoTracking(
        titulo: 'En curso',
        subtitulo: 'Tracking activo',
        icono: Icons.directions_walk_rounded,
      ),
      _PasoTracking(
        titulo: 'Finalizado',
        subtitulo: 'Paseo completado',
        icono: Icons.flag_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estado del recorrido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(pasos.length, (index) {
            final paso = pasos[index];
            final activo = index <= pasoActual;
            final ultimo = index == pasos.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: activo
                            ? colorEstado.withOpacity(0.13)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        paso.icono,
                        size: 18,
                        color: activo ? colorEstado : Colors.grey,
                      ),
                    ),
                    if (!ultimo)
                      Container(
                        width: 2,
                        height: 34,
                        color: activo
                            ? colorEstado.withOpacity(0.45)
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, bottom: ultimo ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paso.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color:
                                activo ? Colors.black87 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          paso.subtitulo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PasoTracking {
  final String titulo;
  final String subtitulo;
  final IconData icono;

  _PasoTracking({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
  });
}

class _BotonesMapa extends StatelessWidget {
  final bool tieneUbicacionActual;
  final double? latActual;
  final double? lngActual;

  const _BotonesMapa({
    required this.tieneUbicacionActual,
    required this.latActual,
    required this.lngActual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: tieneUbicacionActual
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ubicación actual: ${latActual!.toStringAsFixed(6)}, ${lngActual!.toStringAsFixed(6)}',
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Ver ubicación actual'),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Volver al detalle'),
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
      ],
    );
  }
}