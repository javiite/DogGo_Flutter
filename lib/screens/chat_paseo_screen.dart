import 'dart:async';

import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_service.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';

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
  final FocusNode _focusNode = FocusNode();

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
    _focusNode.dispose();
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
      setState(() => _usuarioIdActual = id);
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
        final fechaA = DateTime.tryParse(_valorFecha(a)?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final fechaB = DateTime.tryParse(_valorFecha(b)?.toString() ?? '') ??
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
          _error = e.toString().replaceFirst('Exception: ', '');
          _cargando = false;
        });
      }
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);

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
      if (mounted) setState(() => _enviando = false);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
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

  String _hora(dynamic valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return '';
    final local = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.hour)}:${dos(local.minute)}';
  }

  String _fechaCompleta(dynamic valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return '';
    final local = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year} ${dos(local.hour)}:${dos(local.minute)}';
  }

  bool _mostrarSeparadorFecha(int index) {
    if (index == 0) return true;
    final actual = DateTime.tryParse(_valorFecha(_mensajes[index])?.toString() ?? '');
    final anterior = DateTime.tryParse(_valorFecha(_mensajes[index - 1])?.toString() ?? '');
    if (actual == null || anterior == null) return false;
    return actual.day != anterior.day || actual.month != anterior.month || actual.year != anterior.year;
  }

  String _fechaSeparador(Map<String, dynamic> mensaje) {
    final fecha = DateTime.tryParse(_valorFecha(mensaje)?.toString() ?? '');
    if (fecha == null) return 'Chat del paseo';
    final local = fecha.toLocal();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(local.year, local.month, local.day);
    if (dia == hoy) return 'Hoy';
    if (dia == hoy.subtract(const Duration(days: 1))) return 'Ayer';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(local.day)}/${dos(local.month)}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DogGoTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildConversationHero(),
            Expanded(child: _buildBody()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: DogGoTheme.cream2,
        border: Border(bottom: BorderSide(color: DogGoTheme.border.withOpacity(.75))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: DogGoTheme.ink),
          ),
          const DogGoLogo(size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat del paseo', style: DogGoTheme.title(size: 18)),
                Text(
                  '${_mensajes.length} mensaje${_mensajes.length == 1 ? '' : 's'}',
                  style: DogGoTheme.subtitle(size: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _cargarMensajes(),
            icon: const Icon(Icons.refresh_rounded, color: DogGoTheme.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const BoxDecoration(
        color: DogGoTheme.cream,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DogGoTheme.border),
          boxShadow: DogGoTheme.softShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DogGoTheme.teal, DogGoTheme.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nombrePerro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Conversación con ${widget.nombreOtroUsuario}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(size: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: DogGoTheme.tealLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Paseo',
                style: DogGoTheme.body(size: 11, color: DogGoTheme.teal, weight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_mensajes.isEmpty) return _buildVacio();

    return RefreshIndicator(
      onRefresh: _cargarMensajes,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        itemCount: _mensajes.length,
        itemBuilder: (context, index) {
          final mensaje = _mensajes[index];
          return Column(
            children: [
              if (_mostrarSeparadorFecha(index)) _DateSeparator(texto: _fechaSeparador(mensaje)),
              _buildMensaje(mensaje),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _StateCard(
          icon: Icons.error_outline_rounded,
          iconColor: DogGoTheme.red,
          title: 'No se pudo cargar el chat',
          subtitle: _error ?? 'Intenta actualizar la conversación.',
          buttonText: 'Reintentar',
          onTap: _cargarMensajes,
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _StateCard(
          icon: Icons.forum_rounded,
          iconColor: DogGoTheme.teal,
          title: 'Sin mensajes todavía',
          subtitle: 'Envía el primer mensaje para coordinar hora, punto de recogida o detalles del paseo.',
          buttonText: 'Escribir mensaje',
          onTap: () => _focusNode.requestFocus(),
        ),
      ),
    );
  }

  Widget _buildMensaje(Map<String, dynamic> mensaje) {
    final mio = _esMio(mensaje);
    final contenido = _contenidoMensaje(mensaje);
    final hora = _hora(_valorFecha(mensaje));
    final fechaCompleta = _fechaCompleta(_valorFecha(mensaje));
    final nombre = mio ? 'Tú' : _nombreEmisor(mensaje);

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          if (fechaCompleta.isNotEmpty) _mostrarMensaje(fechaCompleta);
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .76),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
          decoration: BoxDecoration(
            color: mio ? DogGoTheme.teal : DogGoTheme.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(mio ? 22 : 7),
              bottomRight: Radius.circular(mio ? 7 : 22),
            ),
            border: mio ? null : Border.all(color: DogGoTheme.border),
            boxShadow: DogGoTheme.softShadow(),
          ),
          child: Column(
            crossAxisAlignment: mio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DogGoTheme.body(
                  size: 11.5,
                  color: mio ? Colors.white.withOpacity(.8) : DogGoTheme.muted,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                contenido,
                style: DogGoTheme.body(
                  size: 14.2,
                  color: mio ? Colors.white : DogGoTheme.ink,
                  weight: FontWeight.w700,
                ).copyWith(height: 1.3),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hora,
                    style: DogGoTheme.body(
                      size: 10.5,
                      color: mio ? Colors.white.withOpacity(.72) : DogGoTheme.muted,
                      weight: FontWeight.w800,
                    ),
                  ),
                  if (mio) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withOpacity(.72)),
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
          color: DogGoTheme.card,
          border: Border(top: BorderSide(color: DogGoTheme.border.withOpacity(.7))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 16, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mensajeController,
                focusNode: _focusNode,
                enabled: !_enviando,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviarMensaje(),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  prefixIcon: const Icon(Icons.message_rounded, color: DogGoTheme.teal),
                  filled: true,
                  fillColor: DogGoTheme.cream,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarMensaje,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: DogGoTheme.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                ),
                child: _enviando
                    ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DogGoTheme.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: DogGoTheme.border),
        boxShadow: DogGoTheme.softShadow(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: iconColor.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 38),
          ),
          const SizedBox(height: 15),
          Text(title, textAlign: TextAlign.center, style: DogGoTheme.title(size: 22)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: DogGoTheme.subtitle(size: 13.5)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(onPressed: onTap, style: DogGoTheme.primaryButton(), child: Text(buttonText)),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String texto;

  const _DateSeparator({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Text(texto, style: DogGoTheme.subtitle(size: 11.5)),
        ),
      ),
    );
  }
}
