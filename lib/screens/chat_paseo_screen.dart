import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_service.dart';

class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);

  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);

  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);

  static const rose = Color(0xFFEF4444);
  static const roseSurf = Color(0xFFFEEEEE);

  static const blue = Color(0xFF2563EB);
  static const blueSurf = Color(0xFFEFF6FF);

  static const bg = Color(0xFFF4F0E8);
  static const surface = Colors.white;
  static const ink = Color(0xFF111827);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static List<BoxShadow> shadow({
    double opacity = .055,
    double blur = 16,
    Offset offset = const Offset(0, 5),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
}

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double spacing = 0,
  double height = 1.2,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: spacing,
    height: height,
  );
}

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

      return nombre.contains('yo') ||
          nombre.contains('tú') ||
          nombre.contains('tu');
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

  bool _mostrarSeparadorFecha(int index) {
    if (index == 0) return true;

    final actual = DateTime.tryParse(
      _valorFecha(_mensajes[index])?.toString() ?? '',
    );

    final anterior = DateTime.tryParse(
      _valorFecha(_mensajes[index - 1])?.toString() ?? '',
    );

    if (actual == null || anterior == null) return false;

    return actual.day != anterior.day ||
        actual.month != anterior.month ||
        actual.year != anterior.year;
  }

  String _fechaSeparador(Map<String, dynamic> mensaje) {
    final fecha = DateTime.tryParse(
      _valorFecha(mensaje)?.toString() ?? '',
    );

    if (fecha == null) return 'Chat del paseo';

    final local = fecha.toLocal();
    final ahora = DateTime.now();

    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diaMensaje = DateTime(local.year, local.month, local.day);

    if (diaMensaje == hoy) return 'Hoy';

    if (diaMensaje == hoy.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(local.day)}/${dos(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
                child: Text(
                  '💬',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Chat del paseo',
              style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
            ),
          ],
        ),
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
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(14, 14, 14, 18),
                              itemCount: _mensajes.length,
                              itemBuilder: (context, index) {
                                final mensaje = _mensajes[index];

                                return Column(
                                  children: [
                                    if (_mostrarSeparadorFecha(index))
                                      _DateSeparator(
                                        texto: _fechaSeparador(mensaje),
                                      ),
                                    _buildMensaje(mensaje),
                                  ],
                                );
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF089B7A),
            Color(0xFFF4F0E8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Container(
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
                color: _T.teal.withOpacity(.24),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -34,
                right: -34,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: Colors.white.withOpacity(.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SmallPill(
                          text: 'CHAT DEL PASEO',
                          color: Colors.white,
                          background: Colors.white.withOpacity(.16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.nombrePerro,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                            20,
                            FontWeight.w900,
                            Colors.white,
                            spacing: -.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Conversación con ${widget.nombreOtroUsuario}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _ts(
                            12.5,
                            FontWeight.w500,
                            Colors.white.withOpacity(.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(.22),
                      ),
                    ),
                    child: Text(
                      '${_mensajes.length}',
                      style: _ts(12, FontWeight.w900, Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _T.shadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: _T.rose.withOpacity(.88),
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'No se pudo cargar el chat.',
                style: _ts(18, FontWeight.w900, _T.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
                style: _ts(12.5, FontWeight.w500, _T.inkSub, height: 1.3),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarMensajes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: _T.shadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: _T.tealSurface,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '💬',
                    style: TextStyle(fontSize: 42),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Todavía no hay mensajes.',
                style: _ts(18, FontWeight.w900, _T.ink),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Envía el primer mensaje para coordinar el paseo.',
                textAlign: TextAlign.center,
                style: _ts(13, FontWeight.w500, _T.inkSub, height: 1.3),
              ),
            ],
          ),
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
      child: GestureDetector(
        onLongPress: () {
          if (fechaCompleta.isNotEmpty) {
            _mostrarMensaje(fechaCompleta);
          }
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 315),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
          decoration: BoxDecoration(
            gradient: mio
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0EC9A0),
                      Color(0xFF089B7A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: mio ? null : _T.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(19),
              topRight: const Radius.circular(19),
              bottomLeft: Radius.circular(mio ? 19 : 5),
              bottomRight: Radius.circular(mio ? 5 : 19),
            ),
            border: mio
                ? null
                : Border.all(
                    color: _T.stroke,
                    width: .8,
                  ),
            boxShadow: _T.shadow(
              opacity: .04,
              blur: 12,
              offset: const Offset(0, 4),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                mio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mio) ...[
                    Container(
                      width: 21,
                      height: 21,
                      decoration: const BoxDecoration(
                        color: _T.blueSurf,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: _T.blue,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                        11.5,
                        FontWeight.w900,
                        mio ? Colors.white.withOpacity(.88) : _T.inkSub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                contenido,
                style: _ts(
                  14,
                  FontWeight.w600,
                  mio ? Colors.white : _T.ink,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fecha,
                    style: _ts(
                      10.5,
                      FontWeight.w700,
                      mio ? Colors.white.withOpacity(.74) : _T.inkSub,
                    ),
                  ),
                  if (mio) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(.74),
                    ),
                  ],
                ],
              ),
            ],
          ),
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
          color: _T.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.07),
              blurRadius: 16,
              offset: const Offset(0, -5),
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
                  prefixIcon: const Icon(
                    Icons.message_rounded,
                    color: _T.tealDeep,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F4EC),
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
              width: 50,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarMensaje,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: _T.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
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

class _DateSeparator extends StatelessWidget {
  final String texto;

  const _DateSeparator({
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.stroke),
            boxShadow: _T.shadow(
              opacity: .03,
              blur: 8,
              offset: const Offset(0, 2),
            ),
          ),
          child: Text(
            texto,
            style: _ts(11, FontWeight.w800, _T.inkSub),
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const _SmallPill({
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(.18),
        ),
      ),
      child: Text(
        text,
        style: _ts(9.5, FontWeight.w900, color, spacing: 1.1),
      ),
    );
  }
}