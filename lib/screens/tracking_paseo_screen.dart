import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/background_tracking_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/tracking_service.dart';

class G {
  static const brand = Color(0xFF0D9E7E);
  static const brandPale = Color(0xFFE8F8F3);
  static const brandDark = Color(0xFF0A7A62);
  static const clay = Color(0xFFD4694A);
  static const clayLight = Color(0xFFFAEDE8);
  static const sage = Color(0xFF5B8C5A);
  static const sagePale = Color(0xFFECF4EB);
  static const gold = Color(0xFFCB9B3B);
  static const goldPale = Color(0xFFFBF3E0);
  static const ink0 = Color(0xFFFAF7F2);
  static const ink1 = Color(0xFFF3EFE8);
  static const ink2 = Color(0xFFE8E2D9);
  static const ink4 = Color(0xFF8C8278);
  static const ink5 = Color(0xFF4A4540);
  static const ink6 = Color(0xFF1E1A16);
  static const white = Color(0xFFFFFFFF);

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static const shadow1 = [
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
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

  static TextStyle body(Color c, {double size = 13.5}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: c,
      );

  static TextStyle label(Color c, {double size = 12}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: c,
        letterSpacing: .3,
      );
}

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

  Position? _ultimaPosicion;
  DateTime? _ultimaActualizacion;

  bool _trackingActivo = false;
  bool _servicioCorriendo = false;
  bool _enviando = false;
  bool _huboCambios = false;
  int _enviosCorrectos = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarEstado();
  }

  Future<void> _cargarEstado() async {
    final tracking = await StorageService.obtenerTrackingActivo();
    final corriendo = await BackgroundTrackingService.estaCorriendo();

    if (!mounted) return;

    DateTime? ultimaFecha;
    Position? posicion;

    if (tracking != null) {
      final ultimoEnvio = tracking['ultimoEnvio'];

      if (ultimoEnvio != null) {
        ultimaFecha = DateTime.tryParse(ultimoEnvio.toString());
      }

      final lat = tracking['latitud'];
      final lng = tracking['longitud'];

      if (lat is double && lng is double) {
        posicion = Position(
          longitude: lng,
          latitude: lat,
          timestamp: ultimaFecha ?? DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }

    final mismoPaseo = tracking != null &&
        tracking['paseoId']?.toString() == widget.paseoId.toString();

    setState(() {
      _servicioCorriendo = corriendo;
      _trackingActivo = corriendo && mismoPaseo;
      _ultimaActualizacion = ultimaFecha;
      _ultimaPosicion = posicion;
    });
  }

  Future<void> _activarSegundoPlano() async {
    if (_trackingActivo || _enviando) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _locationService.pedirPermisoUbicacion();

      final iniciado = await BackgroundTrackingService.iniciarTracking(
        paseoId: widget.paseoId,
        nombrePerro: widget.nombrePerro,
        nombrePaseador: widget.nombrePaseador,
      );

      if (!mounted) return;

      if (iniciado) {
        setState(() {
          _trackingActivo = true;
          _servicioCorriendo = true;
          _huboCambios = true;
        });

        _snack('Ubicación en vivo activada en segundo plano.');

        await Future.delayed(const Duration(seconds: 2));
        await _cargarEstado();
      } else {
        setState(() {
          _error = 'No se pudo iniciar el servicio de ubicación.';
        });

        _snack('No se pudo activar la ubicación en vivo.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
      });

      _snack('No se pudo activar la ubicación.');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  Future<void> _pausarSegundoPlano() async {
    if (!_trackingActivo && !_servicioCorriendo) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: G.white,
          shape: const RoundedRectangleBorder(borderRadius: G.r20),
          title: Text('Pausar ubicación', style: G.h3(G.ink6)),
          content: Text(
            'Se detendrá el envío de ubicación en segundo plano. La última ubicación enviada seguirá visible en el mapa.',
            style: G.body(G.ink4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: G.label(G.ink4)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: G.clay,
                foregroundColor: G.white,
                shape: const RoundedRectangleBorder(borderRadius: G.r12),
                elevation: 0,
              ),
              child: Text('Pausar', style: G.label(G.white)),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await BackgroundTrackingService.detenerTracking();

      if (!mounted) return;

      setState(() {
        _trackingActivo = false;
        _servicioCorriendo = false;
        _huboCambios = true;
      });

      _snack('Ubicación en vivo pausada.');
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

  Future<void> _actualizarUnaVez() async {
    if (_enviando) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await _locationService.pedirPermisoUbicacion();

      final pos = await _locationService.obtenerUbicacionActual();

      await _trackingService.enviarUbicacion(
        paseoId: widget.paseoId,
        latitud: pos.latitude,
        longitud: pos.longitude,
      );

      final fecha = DateTime.now();

      await StorageService.guardarUltimaUbicacionTracking(
        latitud: pos.latitude,
        longitud: pos.longitude,
        fecha: fecha,
      );

      if (!mounted) return;

      setState(() {
        _ultimaPosicion = pos;
        _ultimaActualizacion = fecha;
        _enviosCorrectos++;
        _huboCambios = true;
      });

      _snack('Ubicación actualizada correctamente.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _limpiarError(e);
      });

      _snack('No se pudo actualizar la ubicación.');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  Future<void> _salir() async {
    Navigator.pop(context, _huboCambios || _trackingActivo);
  }

  String _limpiarError(Object e) {
    final texto = e.toString();

    return texto
        .replaceFirst('Exception: ', '')
        .replaceFirst('Exception:', '')
        .trim();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
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
  }

  String _hora(DateTime? dt) {
    if (dt == null) return 'Aún no enviada';

    String d(int n) => n.toString().padLeft(2, '0');

    return '${d(dt.hour)}:${d(dt.minute)}:${d(dt.second)}';
  }

  String get _coordenadas {
    final p = _ultimaPosicion;

    if (p == null) return 'Sin ubicación';

    return _locationService.formatearCoordenadas(p);
  }

  String get _precision {
    if (_ultimaPosicion == null) return 'N/D';

    if (_ultimaPosicion!.accuracy <= 0) return 'N/D';

    return '${_ultimaPosicion!.accuracy.toStringAsFixed(1)} m';
  }

  String get _velocidad {
    final v = _ultimaPosicion?.speed ?? -1;

    if (v < 0 || v.isNaN) return 'N/D';

    return '${(v * 3.6).toStringAsFixed(1)} km/h';
  }

  String get _altura {
    if (_ultimaPosicion == null) return 'N/D';

    if (_ultimaPosicion!.altitude == 0) return 'N/D';

    return '${_ultimaPosicion!.altitude.toStringAsFixed(1)} m';
  }

  Color get _color {
    if (_trackingActivo) return G.sage;
    if (_ultimaActualizacion != null || _enviosCorrectos > 0) return G.gold;
    return Colors.grey;
  }

  String get _estadoTexto {
    if (_trackingActivo) return 'Ubicación en vivo activa';
    if (_ultimaActualizacion != null || _enviosCorrectos > 0) {
      return 'Última ubicación registrada';
    }
    return 'Sin iniciar';
  }

  String get _estadoDesc {
    if (_trackingActivo) {
      return 'DogGo está enviando ubicación en segundo plano. Puedes volver al detalle o al inicio.';
    }

    if (_ultimaActualizacion != null || _enviosCorrectos > 0) {
      return 'La última ubicación enviada está disponible en el mapa del paseo.';
    }

    return 'Activa la ubicación en vivo para que el dueño vea el avance del paseo.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _salir();
        }
      },
      child: Scaffold(
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
            onPressed: _salir,
          ),
          title: Text('Ubicación en vivo', style: G.h2(G.ink6)),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Actualizar estado',
              icon: const Icon(Icons.refresh_rounded, color: G.ink6),
              onPressed: _enviando ? null : _cargarEstado,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            _estadoCard(),
            const SizedBox(height: 16),
            _ubicacionCard(),
            const SizedBox(height: 16),
            _enviosCard(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _errorCard(),
            ],
            const SizedBox(height: 24),
            _botones(),
            const SizedBox(height: 16),
            _nota(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _trackingActivo ? G.brandDark : G.ink5,
            _trackingActivo ? G.brand : G.ink4,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: G.r24,
        boxShadow: [
          BoxShadow(
            color: (_trackingActivo ? G.brand : G.ink5).withOpacity(.3),
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
              color: Colors.white.withOpacity(.15),
              borderRadius: G.r16,
              border: Border.all(color: Colors.white.withOpacity(.22)),
            ),
            child: Icon(
              _trackingActivo
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS del paseo', style: G.h2(Colors.white)),
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
    );
  }

  Widget _estadoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: G.white,
        borderRadius: G.r20,
        boxShadow: G.shadow1,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _color.withOpacity(.12),
              borderRadius: G.r12,
            ),
            child: Icon(
              _trackingActivo
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: _color,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_estadoTexto, style: G.h3(G.ink6)),
                const SizedBox(height: 4),
                Text(
                  _estadoDesc,
                  style: G.body(G.ink4),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ubicacionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: G.white,
        borderRadius: G.r20,
        boxShadow: G.shadow1,
      ),
      child: Column(
        children: [
          _infoRow(Icons.pin_drop_rounded, 'Coordenadas', _coordenadas),
          _infoRow(Icons.gps_fixed_rounded, 'Precisión', _precision),
          _infoRow(Icons.speed_rounded, 'Velocidad', _velocidad),
          _infoRow(Icons.terrain_rounded, 'Altura', _altura),
          _infoRow(
            Icons.access_time_rounded,
            'Último envío',
            _hora(_ultimaActualizacion),
            isLast: true,
          ),
          if (_enviando)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(color: G.brand),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String titulo,
    String valor, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Icon(icon, color: G.ink4, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: G.label(G.ink4).copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(valor, style: G.h3(G.ink6).copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enviosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: G.white,
        borderRadius: G.r20,
        boxShadow: G.shadow1,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: G.brandPale,
              borderRadius: G.r12,
            ),
            child: const Icon(
              Icons.cloud_done_rounded,
              color: G.brand,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trackingActivo
                      ? 'Servicio activo en segundo plano'
                      : 'Actualizaciones enviadas: $_enviosCorrectos',
                  style: G.h3(G.ink6),
                ),
                const SizedBox(height: 4),
                Text(
                  _trackingActivo
                      ? 'Puedes salir de esta pantalla. Android mostrará una notificación de DogGo mientras se comparte ubicación.'
                      : _enviosCorrectos == 0 && _ultimaActualizacion == null
                          ? 'Todavía no se ha enviado ubicación al servidor.'
                          : 'El dueño podrá ver la última ubicación en el mapa del paseo.',
                  style: G.body(G.ink4),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: G.clayLight,
        borderRadius: G.r16,
        border: Border.all(color: G.clay.withOpacity(.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: G.clay, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? '',
              style: G.body(G.ink6).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botones() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _trackingActivo || _enviando
                ? null
                : _activarSegundoPlano,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Activar ubicación en segundo plano'),
            style: ElevatedButton.styleFrom(
              backgroundColor: G.brand,
              foregroundColor: G.white,
              disabledBackgroundColor: G.ink2,
              shape: const RoundedRectangleBorder(borderRadius: G.r16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _trackingActivo || _servicioCorriendo
                ? _pausarSegundoPlano
                : null,
            icon: const Icon(Icons.pause_rounded),
            label: const Text('Pausar ubicación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: G.clay,
              side: BorderSide(
                color: _trackingActivo || _servicioCorriendo ? G.clay : G.ink2,
                width: 1.5,
              ),
              shape: const RoundedRectangleBorder(borderRadius: G.r16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _enviando ? null : _actualizarUnaVez,
            icon: const Icon(Icons.near_me_rounded),
            label: const Text('Actualizar ubicación ahora'),
            style: OutlinedButton.styleFrom(
              foregroundColor: G.brandDark,
              side: const BorderSide(color: G.brandDark, width: 1.5),
              shape: const RoundedRectangleBorder(borderRadius: G.r16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _nota() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: G.ink1,
        borderRadius: G.r16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: G.ink4, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _trackingActivo
                  ? 'La ubicación seguirá enviándose aunque vuelvas al detalle o al inicio. Para detenerla, vuelve aquí y toca Pausar ubicación o finaliza el paseo.'
                  : 'Activa la ubicación en segundo plano durante el paseo para actualizar el mapa del dueño.',
              style: G.body(G.ink5).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}