import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_service.dart';

class ChatPaseoScreen extends StatefulWidget {
  final int paseoId;
  final String nombrePerro;
  final String nombreOtroUsuario;

  const ChatPaseoScreen({
    super.key,
    required this.paseoId,
    required this.nombrePerro,
    required this.nombreOtroUsuario,
  });

  @override
  State<ChatPaseoScreen> createState() => _ChatPaseoScreenState();
}

class _ChatPaseoScreenState extends State<ChatPaseoScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  String? _error;
  int? _usuarioIdActual;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mensajeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    await _cargarUsuarioActual();
    await _cargarMensajes();

    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_enviando) {
        _cargarMensajes(silencioso: true);
      }
    });
  }

  Future<void> _cargarUsuarioActual() async {
    try {
      final id = await SessionService.obtenerUsuarioId();

      if (!mounted) return;

      setState(() {
        _usuarioIdActual = id;
      });
    } catch (_) {}
  }

  Future<void> _cargarMensajes({bool silencioso = false}) async {
    if (!silencioso) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final mensajes = await _chatService.obtenerMensajesPaseo(widget.paseoId);

      mensajes.sort((a, b) {
        final fechaA = DateTime.tryParse(
              _valorFecha(a)?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final fechaB = DateTime.tryParse(
              _valorFecha(b)?.toString() ?? '',
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return fechaA.compareTo(fechaB);
      });

      if (!mounted) return;

      setState(() {
        _mensajes = mensajes;
        _cargando = false;
        _error = null;
      });

      _bajarAlFinal();
    } catch (e) {
      if (!mounted) return;

      if (!silencioso) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();

    if (texto.isEmpty || _enviando) return;

    setState(() {
      _enviando = true;
    });

    try {
      await _chatService.enviarMensaje(
        paseoId: widget.paseoId,
        contenido: texto,
      );

      _mensajeController.clear();

      await _cargarMensajes(silencioso: true);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensaje('No se pudo enviar el mensaje: $e');
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _bajarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  dynamic _valorFecha(Map<String, dynamic> mensaje) {
    return mensaje['fecha'] ??
        mensaje['Fecha'] ??
        mensaje['fechaEnvio'] ??
        mensaje['FechaEnvio'] ??
        mensaje['createdAt'] ??
        mensaje['timestamp'] ??
        mensaje['Timestamp'];
  }

  String _texto(dynamic valor, {String fallback = ''}) {
    if (valor == null) return fallback;
    final texto = valor.toString().trim();
    if (texto.isEmpty || texto.toLowerCase() == 'null') return fallback;
    return texto;
  }

  String _contenidoMensaje(Map<String, dynamic> mensaje) {
    return _texto(
      mensaje['contenido'] ??
          mensaje['Contenido'] ??
          mensaje['mensaje'] ??
          mensaje['Mensaje'] ??
          mensaje['texto'] ??
          mensaje['Texto'] ??
          mensaje['body'] ??
          mensaje['Body'],
      fallback: '',
    );
  }

  int? _emisorId(Map<String, dynamic> mensaje) {
    final valor = mensaje['emisorId'] ??
        mensaje['EmisorId'] ??
        mensaje['usuarioId'] ??
        mensaje['UsuarioId'] ??
        mensaje['senderId'] ??
        mensaje['SenderId'] ??
        mensaje['fromUserId'] ??
        mensaje['FromUserId'];

    if (valor is int) return valor;
    return int.tryParse(valor?.toString() ?? '');
  }

  String _nombreEmisor(Map<String, dynamic> mensaje) {
    return _texto(
      mensaje['emisorNombre'] ??
          mensaje['EmisorNombre'] ??
          mensaje['usuarioNombre'] ??
          mensaje['UsuarioNombre'] ??
          mensaje['senderName'] ??
          mensaje['SenderName'] ??
          mensaje['nombreEmisor'] ??
          mensaje['NombreEmisor'],
      fallback: 'Usuario',
    );
  }

  bool _esMio(Map<String, dynamic> mensaje) {
    final emisor = _emisorId(mensaje);

    if (_usuarioIdActual == null || emisor == null) {
      final nombre = _nombreEmisor(mensaje).toLowerCase();
      return nombre.contains('yo') || nombre.contains('tú') || nombre.contains('tu');
    }

    return emisor == _usuarioIdActual;
  }

  String _fechaBonita(dynamic valor) {
    if (valor == null) return '';

    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return '';

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.hour)}:${dos(local.minute)}';
  }

  String _fechaCompleta(dynamic valor) {
    if (valor == null) return '';

    final fecha = DateTime.tryParse(valor.toString());
    if (fecha == null) return '';

    final local = fecha.toLocal();

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Chat del paseo'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _cargarMensajes(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _mensajes.isEmpty
                        ? _buildVacio()
                        : RefreshIndicator(
                            onRefresh: _cargarMensajes,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                              itemCount: _mensajes.length,
                              itemBuilder: (context, index) {
                                return _buildMensaje(_mensajes[index]);
                              },
                            ),
                          ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1F8A70),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nombrePerro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Conversación con ${widget.nombreOtroUsuario}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Paseo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 58,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar el chat.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarMensajes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8A70),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_rounded,
              color: Colors.grey.shade400,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'Todavía no hay mensajes.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Envía el primer mensaje para coordinar el paseo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMensaje(Map<String, dynamic> mensaje) {
    final mio = _esMio(mensaje);
    final contenido = _contenidoMensaje(mensaje);
    final fecha = _fechaBonita(_valorFecha(mensaje));
    final fechaCompleta = _fechaCompleta(_valorFecha(mensaje));
    final nombre = mio ? 'Tú' : _nombreEmisor(mensaje);

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
        decoration: BoxDecoration(
          color: mio ? const Color(0xFF1F8A70) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mio ? 18 : 4),
            bottomRight: Radius.circular(mio ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
              mio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: TextStyle(
                color: mio ? Colors.white.withOpacity(0.85) : Colors.grey.shade600,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contenido,
              style: TextStyle(
                color: mio ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              fechaCompleta.isEmpty ? fecha : fecha,
              style: TextStyle(
                color: mio ? Colors.white.withOpacity(0.74) : Colors.grey.shade500,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mensajeController,
                enabled: !_enviando,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: const Color(0xFFF4F6F8),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarMensaje,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF1F8A70),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}