import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/tracking_service.dart';

class TrackingPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombrePaseador;

  const TrackingPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombrePaseador,
  });

  @override
  State<TrackingPaseoScreen> createState() => _TrackingPaseoScreenState();
}

class _TrackingPaseoScreenState extends State<TrackingPaseoScreen> {
  final LocationService _locationService = LocationService();
  final TrackingService _trackingService = TrackingService();

  StreamSubscription<Position>? _subscription;
  Timer? _timer;

  Position? _ultimaPosicion;
  DateTime? _ultimaActualizacion;

  bool _trackingActivo = false;
  bool _enviando = false;
  bool _huboCambios = false;

  int _enviosCorrectos = 0;
  String? _error;

  static const Duration _intervaloEnvio = Duration(seconds: 15);

  @override
  void dispose() {
    _detenerTrackingSinDialogo();
    super.dispose();
  }

  Future<void> _obtenerYEnviarUnaVez() async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _locationService.pedirPermisoUbicacion();

      final posicion = await _locationService.obtenerUbicacionActual();

      await _trackingService.enviarUbicacion(
        paseoId: widget.paseoId,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );

      if (!mounted) return;

      setState(() {
        _ultimaPosicion = posicion;
        _ultimaActualizacion = DateTime.now();
        _enviosCorrectos++;
        _error = null;
        _huboCambios = true;
      });

      _mostrarMensaje('Ubicación enviada correctamente.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
      });

      _mostrarMensaje('No se pudo enviar la ubicación.');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  Future<void> _iniciarTracking() async {
    if (_trackingActivo || _enviando) return;

    setState(() {
      _trackingActivo = true;
      _error = null;
    });

    try {
      await _locationService.pedirPermisoUbicacion();

      await _obtenerYEnviarUnaVez();

      if (!mounted || !_trackingActivo) return;

      _subscription?.cancel();

      _subscription = _locationService.escucharUbicacion().listen(
        (posicion) async {
          if (!_trackingActivo || _enviando) return;

          setState(() {
            _ultimaPosicion = posicion;
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _error = _limpiarError(error);
          });
        },
      );

      _timer?.cancel();

      _timer = Timer.periodic(_intervaloEnvio, (_) async {
        if (!_trackingActivo || _enviando) return;

        final posicion = _ultimaPosicion;

        if (posicion != null) {
          await _enviarPosicionSilenciosa(posicion);
        } else {
          await _obtenerYEnviarUnaVez();
        }
      });

      if (!mounted) return;

      _mostrarMensaje('Tracking iniciado.');
    } catch (e) {
      _detenerTrackingSinDialogo();

      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
      });

      _mostrarMensaje('No se pudo iniciar el tracking.');
    }
  }

  Future<void> _enviarPosicionSilenciosa(Position posicion) async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _trackingService.enviarUbicacion(
        paseoId: widget.paseoId,
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );

      if (!mounted) return;

      setState(() {
        _ultimaPosicion = posicion;
        _ultimaActualizacion = DateTime.now();
        _enviosCorrectos++;
        _error = null;
        _huboCambios = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _detenerTrackingSinDialogo() {
    _trackingActivo = false;

    _subscription?.cancel();
    _subscription = null;

    _timer?.cancel();
    _timer = null;
  }

  Future<void> _confirmarDetener() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detener tracking'),
          content: const Text(
            '¿Quieres detener el envío de ubicación en tiempo real?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir enviando'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Detener'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    _detenerTrackingSinDialogo();

    if (!mounted) return;

    setState(() {});

    _mostrarMensaje('Tracking detenido.');
  }

  Future<bool> _confirmarSalidaSiActivo() async {
    if (!_trackingActivo) return true;

    final salir = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salir del tracking'),
          content: const Text(
            'Si sales de esta pantalla, se detendrá el envío de ubicación. '
            'Para esta versión de prueba, mantén la pantalla abierta durante el paseo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quedarme'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    return salir == true;
  }

  Future<void> _salir() async {
    final puedeSalir = await _confirmarSalidaSiActivo();

    if (!puedeSalir) return;

    _detenerTrackingSinDialogo();

    if (!mounted) return;

    Navigator.pop(context, _huboCambios);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  String _limpiarError(dynamic error) {
    final texto = error.toString().trim();

    if (texto.isEmpty) {
      return 'Ocurrió un error desconocido.';
    }

    return texto;
  }

  String _fechaBonita(DateTime? fecha) {
    if (fecha == null) return 'Aún no enviada';

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.hour)}:${dos(fecha.minute)}:${dos(fecha.second)}';
  }

  String _coordenadas() {
    final posicion = _ultimaPosicion;

    if (posicion == null) {
      return 'Sin ubicación todavía';
    }

    return _locationService.formatearCoordenadas(posicion);
  }

  String _precision() {
    final posicion = _ultimaPosicion;

    if (posicion == null) {
      return 'No disponible';
    }

    return '${posicion.accuracy.toStringAsFixed(1)} m';
  }

  String _velocidad() {
    final posicion = _ultimaPosicion;

    if (posicion == null) {
      return 'No disponible';
    }

    final velocidadMps = posicion.speed;

    if (velocidadMps.isNaN || velocidadMps < 0) {
      return 'No disponible';
    }

    final velocidadKmh = velocidadMps * 3.6;

    return '${velocidadKmh.toStringAsFixed(1)} km/h';
  }

  String _altura() {
    final posicion = _ultimaPosicion;

    if (posicion == null) {
      return 'No disponible';
    }

    return '${posicion.altitude.toStringAsFixed(1)} m';
  }

  String _estadoTexto() {
    if (_trackingActivo) {
      return 'Tracking activo';
    }

    if (_enviosCorrectos > 0) {
      return 'Tracking detenido';
    }

    return 'Tracking sin iniciar';
  }

  String _estadoDescripcion() {
    if (_trackingActivo) {
      return 'La app está enviando ubicación al servidor cada ${_intervaloEnvio.inSeconds} segundos.';
    }

    if (_enviosCorrectos > 0) {
      return 'Ya se enviaron ubicaciones. Puedes volver a iniciar si el paseo sigue activo.';
    }

    return 'Presiona iniciar para comenzar a enviar ubicación GPS.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _trackingActivo
        ? Colors.green
        : _enviosCorrectos > 0
            ? Colors.orange
            : Colors.grey;

    return WillPopScope(
      onWillPop: () async {
        await _salir();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          title: const Text('Tracking GPS'),
          backgroundColor: const Color(0xFF1F8A70),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _salir,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(color),
              const SizedBox(height: 16),
              _buildEstadoCard(color),
              const SizedBox(height: 16),
              _buildUbicacionCard(),
              const SizedBox(height: 16),
              _buildEnviosCard(),
              const SizedBox(height: 16),
              if (_error != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 16),
              ],
              _buildBotones(),
              const SizedBox(height: 14),
              _buildNota(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color == Colors.green ? const Color(0xFF1F8A70) : color,
            color == Colors.green
                ? const Color(0xFF35A98A)
                : color.withOpacity(0.72),
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
              _trackingActivo
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS del paseo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Perro: ${widget.nombrePerro}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Paseador: ${widget.nombrePaseador}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoCard(Color color) {
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
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _trackingActivo
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estadoTexto(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _estadoDescripcion(),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionCard() {
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
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoTrackingRow(
            icono: Icons.pin_drop_rounded,
            titulo: 'Coordenadas',
            valor: _coordenadas(),
          ),
          _InfoTrackingRow(
            icono: Icons.gps_fixed_rounded,
            titulo: 'Precisión',
            valor: _precision(),
          ),
          _InfoTrackingRow(
            icono: Icons.speed_rounded,
            titulo: 'Velocidad',
            valor: _velocidad(),
          ),
          _InfoTrackingRow(
            icono: Icons.terrain_rounded,
            titulo: 'Altura',
            valor: _altura(),
          ),
          _InfoTrackingRow(
            icono: Icons.access_time_rounded,
            titulo: 'Último envío',
            valor: _fechaBonita(_ultimaActualizacion),
          ),
          if (_enviando)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildEnviosCard() {
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
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F8A70).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: Color(0xFF1F8A70),
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Envíos correctos: $_enviosCorrectos',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _enviosCorrectos == 0
                      ? 'Todavía no se ha enviado ninguna ubicación al servidor.'
                      : 'El mapa del dueño podrá mostrar la última ubicación enviada.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withOpacity(0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? '',
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

  Widget _buildBotones() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _trackingActivo || _enviando ? null : _iniciarTracking,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar tracking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _trackingActivo ? _confirmarDetener : null,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Detener tracking'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              disabledForegroundColor: Colors.grey.shade500,
              side: BorderSide(
                color: _trackingActivo ? Colors.red : Colors.grey.shade300,
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _enviando ? null : _obtenerYEnviarUnaVez,
            icon: const Icon(Icons.near_me_rounded),
            label: const Text('Enviar ubicación una vez'),
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
              'Para esta versión de prueba, mantén esta pantalla abierta durante el paseo. '
              'Si sales, se detiene el envío automático. Con Cloudflare usa tu URL HTTPS como base URL en configuración, sin agregar /api al final.',
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

class _InfoTrackingRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoTrackingRow({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icono,
            color: Colors.grey.shade700,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
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