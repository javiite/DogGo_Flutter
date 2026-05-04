import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
class G {
  static const brand = Color(0xFF0D9E7E);
  static const brandPale = Color(0xFFE8F8F3);
  static const brandDark = Color(0xFF0A7A62);
  static const clay = Color(0xFFD4694A);
  static const clayLight = Color(0xFFFAEDE8); // Faltaba este
  static const sage = Color(0xFF5B8C5A);
  static const sagePale = Color(0xFFECF4EB);
  static const gold = Color(0xFFCB9B3B);
  static const goldPale = Color(0xFFFBF3E0);
  static const plum = Color(0xFF6B4E8A);
  static const plumPale = Color(0xFFF2EDF8);
  static const ink0 = Color(0xFFFAF7F2);
  static const ink1 = Color(0xFFF3EFE8); // Faltaba este
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

  static const Duration _intervalo = Duration(seconds: 15);

  @override
  void dispose() {
    _detener();
    super.dispose();
  }

  Future<void> _obtenerYEnviar() async {
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
      if (!mounted) return;
      setState(() {
        _ultimaPosicion = pos;
        _ultimaActualizacion = DateTime.now();
        _enviosCorrectos++;
        _error = null;
        _huboCambios = true;
      });
      _snack('Ubicación enviada ✅');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      _snack('No se pudo enviar la ubicación');
    } finally {
      if (mounted)
        setState(() {
          _enviando = false;
        });
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
      await _obtenerYEnviar();
      if (!mounted || !_trackingActivo) return;
      _subscription?.cancel();
      _subscription = _locationService.escucharUbicacion().listen(
        (pos) {
          if (_trackingActivo && !_enviando)
            setState(() => _ultimaPosicion = pos);
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _error = e.toString());
        },
      );
      _timer?.cancel();
      _timer = Timer.periodic(_intervalo, (_) async {
        if (!_trackingActivo || _enviando) return;
        final pos = _ultimaPosicion;
        if (pos != null)
          await _enviarSilencioso(pos);
        else
          await _obtenerYEnviar();
      });
      if (!mounted) return;
      _snack('Tracking iniciado 🐾');
    } catch (e) {
      _detener();
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      _snack('No se pudo iniciar el tracking');
    }
  }

  Future<void> _enviarSilencioso(Position pos) async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
    });
    try {
      await _trackingService.enviarUbicacion(
        paseoId: widget.paseoId,
        latitud: pos.latitude,
        longitud: pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        _ultimaPosicion = pos;
        _ultimaActualizacion = DateTime.now();
        _enviosCorrectos++;
        _error = null;
        _huboCambios = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _enviando = false;
        });
    }
  }

  void _detener() {
    _trackingActivo = false;
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _confirmarDetener() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: G.white,
        shape: const RoundedRectangleBorder(borderRadius: G.r20),
        title: Text('Detener tracking', style: G.h3(G.ink6)),
        content: Text(
          '¿Quieres detener el envío de ubicación?',
          style: G.body(G.ink4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Seguir', style: G.label(G.ink4)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: G.clay,
              foregroundColor: G.white,
              shape: const RoundedRectangleBorder(borderRadius: G.r12),
              elevation: 0,
            ),
            child: Text('Detener', style: G.label(G.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _detener();
    if (!mounted) return;
    setState(() {});
    _snack('Tracking detenido');
  }

  Future<bool> _confirmarSalida() async {
    if (!_trackingActivo) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: G.white,
        shape: const RoundedRectangleBorder(borderRadius: G.r20),
        title: Text('Salir del tracking', style: G.h3(G.ink6)),
        content: Text(
          'Si sales se detendrá el envío de ubicación. Mantén la pantalla abierta durante el paseo.',
          style: G.body(G.ink4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Quedarme', style: G.label(G.ink4)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: G.brand,
              foregroundColor: G.white,
              shape: const RoundedRectangleBorder(borderRadius: G.r12),
              elevation: 0,
            ),
            child: Text('Salir', style: G.label(G.white)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _salir() async {
    if (await _confirmarSalida()) {
      _detener();
      if (!mounted) return;
      Navigator.pop(context, _huboCambios);
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

  String get _precision => _ultimaPosicion == null
      ? 'N/D'
      : '${_ultimaPosicion!.accuracy.toStringAsFixed(1)} m';
  String get _velocidad {
    final v = _ultimaPosicion?.speed ?? -1;
    if (v < 0 || v.isNaN) return 'N/D';
    return '${(v * 3.6).toStringAsFixed(1)} km/h';
  }

  String get _altura => _ultimaPosicion == null
      ? 'N/D'
      : '${_ultimaPosicion!.altitude.toStringAsFixed(1)} m';

  Color get _color => _trackingActivo
      ? G.sage
      : _enviosCorrectos > 0
      ? G.gold
      : Colors.grey;
  String get _estadoTexto => _trackingActivo
      ? 'Tracking activo'
      : _enviosCorrectos > 0
      ? 'Tracking detenido'
      : 'Sin iniciar';
  String get _estadoDesc => _trackingActivo
      ? 'Enviando ubicación al servidor cada ${_intervalo.inSeconds}s.'
      : _enviosCorrectos > 0
      ? 'Ya se enviaron ubicaciones. Puedes volver a iniciar.'
      : 'Presiona iniciar para comenzar a enviar GPS.';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvoked: (did) async {
      if (!did) await _salir();
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
        title: Text('Tracking GPS', style: G.h2(G.ink6)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: G.ink6),
            onPressed: _obtenerYEnviar,
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
          if (_error != null) ...[const SizedBox(height: 16), _errorCard()],
          const SizedBox(height: 24),
          _botones(),
          const SizedBox(height: 16),
          _nota(),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );

  Widget _headerCard() => Container(
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

  Widget _estadoCard() => Container(
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
              Text(_estadoDesc, style: G.body(G.ink4), maxLines: 2),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _ubicacionCard() => Container(
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

  Widget _infoRow(
    IconData icon,
    String titulo,
    String valor, {
    bool isLast = false,
  }) => Padding(
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

  Widget _enviosCard() => Container(
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
          child: const Icon(Icons.cloud_done_rounded, color: G.brand, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Envíos correctos: $_enviosCorrectos', style: G.h3(G.ink6)),
              const SizedBox(height: 4),
              Text(
                _enviosCorrectos == 0
                    ? 'No se ha enviado ninguna ubicación.'
                    : 'El dueño puede ver la última ubicación.',
                style: G.body(G.ink4),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _errorCard() => Container(
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

  Widget _botones() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _trackingActivo || _enviando ? null : _iniciarTracking,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Iniciar tracking'),
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
          onPressed: _trackingActivo ? _confirmarDetener : null,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Detener tracking'),
          style: OutlinedButton.styleFrom(
            foregroundColor: G.clay,
            side: BorderSide(
              color: _trackingActivo ? G.clay : G.ink2,
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
          onPressed: _enviando ? null : _obtenerYEnviar,
          icon: const Icon(Icons.near_me_rounded),
          label: const Text('Enviar una vez'),
          style: OutlinedButton.styleFrom(
            foregroundColor: G.brandDark,
            side: const BorderSide(color: G.brandDark, width: 1.5),
            shape: const RoundedRectangleBorder(borderRadius: G.r16),
          ),
        ),
      ),
    ],
  );

  Widget _nota() => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(color: G.ink1, borderRadius: G.r16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: G.ink4, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mantén esta pantalla abierta durante el paseo. Si sales se detiene el envío automático.',
            style: G.body(G.ink5).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
