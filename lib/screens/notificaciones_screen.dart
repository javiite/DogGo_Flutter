import 'package:flutter/material.dart';

import '../services/notificaciones_service.dart';
import 'chat_paseo_screen.dart';
import 'mis_paseos_screen.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final NotificacionesService _notificacionesService = NotificacionesService();

  List<Map<String, dynamic>> _notificaciones = [];
  bool _cargando = true;
  bool _accionando = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _cargando = true;
    });

    try {
      final lista = await _notificacionesService.obtenerNotificaciones();

      lista.sort((a, b) {
        final fechaA = DateTime.tryParse(_fechaValor(a)?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final fechaB = DateTime.tryParse(_fechaValor(b)?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return fechaB.compareTo(fechaA);
      });

      if (!mounted) return;

      setState(() {
        _notificaciones = lista;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _notificaciones = [];
        _cargando = false;
      });
    }
  }

  Future<void> _abrirNotificacion(Map<String, dynamic> notificacion) async {
    if (_accionando) return;

    setState(() {
      _accionando = true;
    });

    final id = _idNotificacion(notificacion);
    final tipo = _tipo(notificacion).toLowerCase();
    final referenciaId = _referenciaId(notificacion);

    try {
      if (id != null && !_leida(notificacion)) {
        await _notificacionesService.marcarComoLeida(id);
      }

      if (!mounted) return;

      if ((tipo.contains('chat') || tipo.contains('mensaje')) &&
          referenciaId != null &&
          referenciaId > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPaseoScreen(
              paseoId: referenciaId,
              nombrePerro: _nombrePerro(notificacion),
              nombreOtroUsuario: _nombreOtroUsuario(notificacion),
            ),
          ),
        );
      } else if (tipo.contains('paseo') ||
          tipo.contains('solicitud') ||
          tipo.contains('aceptado') ||
          tipo.contains('rechazado') ||
          tipo.contains('cancelado') ||
          tipo.contains('finalizado') ||
          tipo.contains('iniciado')) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MisPaseosScreen(),
          ),
        );
      } else {
        await _cargarNotificaciones();
      }

      if (mounted) {
        await _cargarNotificaciones();
      }
    } finally {
      if (mounted) {
        setState(() {
          _accionando = false;
        });
      }
    }
  }

  Future<void> _marcarLeida(Map<String, dynamic> notificacion) async {
    final id = _idNotificacion(notificacion);

    if (id == null || _accionando) return;

    setState(() {
      _accionando = true;
    });

    try {
      await _notificacionesService.marcarComoLeida(id);

      if (!mounted) return;

      await _cargarNotificaciones();
    } finally {
      if (mounted) {
        setState(() {
          _accionando = false;
        });
      }
    }
  }

  int? _idNotificacion(Map<String, dynamic> item) {
    final valor = item['id'] ??
        item['Id'] ??
        item['notificacionId'] ??
        item['NotificacionId'];

    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '');
  }

  int? _referenciaId(Map<String, dynamic> item) {
    final valor = item['referenciaId'] ??
        item['ReferenciaId'] ??
        item['paseoId'] ??
        item['PaseoId'] ??
        item['chatId'] ??
        item['ChatId'] ??
        item['idReferencia'] ??
        item['IdReferencia'];

    if (valor is int) return valor;
    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '');
  }

  dynamic _fechaValor(Map<String, dynamic> item) {
    return item['fecha'] ??
        item['Fecha'] ??
        item['fechaCreacion'] ??
        item['FechaCreacion'] ??
        item['createdAt'] ??
        item['timestamp'];
  }

  String _texto(dynamic valor, {String fallback = ''}) {
    if (valor == null) return fallback;

    final texto = valor.toString().trim();

    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;

    return texto;
  }

  String _titulo(Map<String, dynamic> item) {
    return _texto(
      item['titulo'] ??
          item['Titulo'] ??
          item['title'] ??
          item['asunto'] ??
          item['Asunto'],
      fallback: 'Notificación',
    );
  }

  String _mensaje(Map<String, dynamic> item) {
    return _texto(
      item['mensaje'] ??
          item['Mensaje'] ??
          item['descripcion'] ??
          item['Descripcion'] ??
          item['body'] ??
          item['texto'] ??
          item['Texto'],
      fallback: 'Sin descripción',
    );
  }

  String _tipo(Map<String, dynamic> item) {
    return _texto(
      item['tipo'] ?? item['Tipo'] ?? item['type'],
      fallback: 'General',
    );
  }

  String _nombrePerro(Map<String, dynamic> item) {
    return _texto(
      item['nombrePerro'] ??
          item['NombrePerro'] ??
          item['perroNombre'] ??
          item['PerroNombre'],
      fallback: 'Paseo DogGo',
    );
  }

  String _nombreOtroUsuario(Map<String, dynamic> item) {
    return _texto(
      item['nombreUsuario'] ??
          item['NombreUsuario'] ??
          item['otroUsuario'] ??
          item['OtroUsuario'] ??
          item['emisorNombre'] ??
          item['EmisorNombre'] ??
          item['remitente'] ??
          item['Remitente'],
      fallback: 'Usuario',
    );
  }

  bool _leida(Map<String, dynamic> item) {
    final valor = item['leida'] ??
        item['Leida'] ??
        item['vista'] ??
        item['Vista'] ??
        item['read'] ??
        item['isRead'];

    if (valor is bool) return valor;

    final texto = valor?.toString().toLowerCase();

    return texto == 'true' || texto == '1';
  }

  String _fechaBonita(dynamic valor) {
    if (valor == null) return '';

    final fecha = DateTime.tryParse(valor.toString());

    if (fecha == null) return '';

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  IconData _iconoTipo(String tipo) {
    final t = tipo.toLowerCase();

    if (t.contains('paseo')) return Icons.route_rounded;
    if (t.contains('solicitud')) return Icons.assignment_rounded;
    if (t.contains('chat') || t.contains('mensaje')) return Icons.chat_rounded;
    if (t.contains('cancel')) return Icons.cancel_rounded;
    if (t.contains('perfil')) return Icons.person_rounded;
    if (t.contains('calificacion') || t.contains('rese')) {
      return Icons.star_rounded;
    }

    return Icons.notifications_rounded;
  }

  Color _colorTipo(String tipo) {
    final t = tipo.toLowerCase();

    if (t.contains('paseo')) return const Color(0xFF1F8A70);
    if (t.contains('solicitud')) return const Color(0xFFE08A1E);
    if (t.contains('chat') || t.contains('mensaje')) return Colors.blue;
    if (t.contains('cancel')) return Colors.red;
    if (t.contains('perfil')) return Colors.purple;
    if (t.contains('calificacion') || t.contains('rese')) {
      return Colors.amber.shade700;
    }

    return Colors.grey;
  }

  int get _noLeidas {
    return _notificaciones.where((n) => !_leida(n)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F0E8),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: const Color(0xFF089B7A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarNotificaciones,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarNotificaciones,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  if (_accionando) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                  ],
                  if (_notificaciones.isEmpty)
                    _buildVacio()
                  else
                    ..._notificaciones.map(_buildNotificacionCard),
                  const SizedBox(height: 24),
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
            color: const Color(0xFF0EC9A0).withOpacity(0.22),
            blurRadius: 18,
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
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividad reciente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _noLeidas == 0
                      ? 'No tienes notificaciones pendientes.'
                      : 'Tienes $_noLeidas notificación(es) sin leer.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color: Colors.grey.shade400,
            size: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay notificaciones.',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aquí aparecerán avisos sobre paseos, mensajes, evidencias y cambios importantes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificacionCard(Map<String, dynamic> item) {
    final tipo = _tipo(item);
    final leida = _leida(item);
    final color = _colorTipo(tipo);
    final fecha = _fechaBonita(_fechaValor(item));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: leida ? Colors.white : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: leida ? Colors.transparent : color.withOpacity(0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _abrirNotificacion(item),
        onLongPress: leida ? null : () => _marcarLeida(item),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconoTipo(tipo),
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titulo(item),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                        ),
                        if (!leida)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _mensaje(item),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (fecha.isNotEmpty)
                          Expanded(
                            child: Text(
                              fecha,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Toca para abrir',
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}