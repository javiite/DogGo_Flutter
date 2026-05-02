import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const teal = Color(0xFF0EC9A0);
  static const tealDeep = Color(0xFF089B7A);
  static const tealSurface = Color(0xFFE4FAF4);
  static const violet = Color(0xFF7C5CBF);
  static const violetSurf = Color(0xFFF0EBFA);
  static const amber = Color(0xFFFFAB2E);
  static const amberSurf = Color(0xFFFFF4E0);
  static const emerald = Color(0xFF22C55E);
  static const emeraldSurf = Color(0xFFE6FAF0);
  static const rose = Color(0xFFEF4444);
  static const bg = Color(0xFFF4F0E8);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF111827);
  static const inkMid = Color(0xFF374151);
  static const inkSub = Color(0xFF6B7280);
  static const stroke = Color(0xFFE5E7EB);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r10 = BorderRadius.all(Radius.circular(10));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));

  static List<BoxShadow> shadow({
    double opacity = .07,
    double blur = 20,
    Offset offset = const Offset(0, 6),
  }) => [
    BoxShadow(
      color: Colors.black.withOpacity(opacity),
      blurRadius: blur,
      offset: offset,
    ),
  ];
}

TextStyle _ts(
  double size,
  FontWeight w,
  Color c, {
  double spacing = 0,
  double height = 1.2,
}) => TextStyle(
  fontSize: size,
  fontWeight: w,
  color: c,
  letterSpacing: spacing,
  height: height,
);

// ─────────────────────────────────────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────────────────────────────────────
class _ChatPreview {
  final String nombre, lastMsg, hora, emoji, estado;
  final int unread;
  final Color color;
  const _ChatPreview(
    this.nombre,
    this.lastMsg,
    this.hora,
    this.emoji,
    this.estado,
    this.unread,
    this.color,
  );
}

class _Mensaje {
  final String texto, hora;
  final bool esMio;
  const _Mensaje(this.texto, this.hora, this.esMio);
}

// ─────────────────────────────────────────────────────────────────────────────
//  MENSAJES SCREEN — lista de chats
// ─────────────────────────────────────────────────────────────────────────────
class MensajesScreen extends StatefulWidget {
  const MensajesScreen({super.key});
  @override
  State<MensajesScreen> createState() => _MensajesScreenState();
}

class _MensajesScreenState extends State<MensajesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _chats = [
    _ChatPreview(
      'Carlos Rodríguez',
      'Confirmo el paseo de Max para hoy 🐕',
      '4:28 PM',
      '👨',
      'Confirmado',
      2,
      Color(0xFF0EC9A0),
    ),
    _ChatPreview(
      'María González',
      'El paseo de Luna fue genial hoy ❤️',
      '10:15 AM',
      '👩',
      'Completado',
      0,
      Color(0xFF7C5CBF),
    ),
    _ChatPreview(
      'DogGo Soporte',
      'Tu pago fue procesado exitosamente ✅',
      'Ayer',
      '🐾',
      'Sistema',
      0,
      Color(0xFF22C55E),
    ),
    _ChatPreview(
      'Pedro Martínez',
      '¿A qué hora pasas por Rocky?',
      'Lun',
      '👨',
      'Pendiente',
      1,
      Color(0xFFFFAB2E),
    ),
    _ChatPreview(
      'Ana López',
      'Perfecto, nos vemos mañana 🙌',
      'Dom',
      '👩',
      'Completado',
      0,
      Color(0xFFEF4444),
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _query.isEmpty
        ? _chats
        : _chats
              .where(
                (c) => c.nombre.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Scaffold(
      backgroundColor: _T.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_appBar()],
        body: FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              _searchBar(),
              Expanded(
                child: filtrados.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtrados.length,
                        itemBuilder: (_, i) => _chatTile(filtrados[i], i),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────────
  SliverAppBar _appBar() => SliverAppBar(
    pinned: true,
    backgroundColor: _T.tealDeep,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: _T.r8,
          ),
          child: const Center(
            child: Text('💬', style: TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Mensajes',
          style: _ts(20, FontWeight.w900, Colors.white, spacing: -.4),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
        onPressed: () {},
      ),
      const SizedBox(width: 4),
    ],
  );

  // ── SEARCH BAR ─────────────────────────────────────────────────────────────
  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: _T.r12,
        boxShadow: _T.shadow(
          opacity: .04,
          blur: 10,
          offset: const Offset(0, 2),
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: _ts(13.5, FontWeight.w500, _T.ink),
        decoration: InputDecoration(
          hintText: 'Buscar conversación...',
          hintStyle: _ts(13.5, FontWeight.w400, _T.inkSub),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _T.inkSub,
            size: 20,
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: _T.inkSub,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  // ── CHAT TILE ──────────────────────────────────────────────────────────────
  Widget _chatTile(_ChatPreview c, int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + i * 80),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatIndividualScreen(chat: c)),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: _T.r16,
            boxShadow: _T.shadow(
              opacity: .04,
              blur: 10,
              offset: const Offset(0, 3),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: c.color.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        c.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.unread > 0 ? _T.emerald : _T.stroke,
                        shape: BoxShape.circle,
                        border: Border.all(color: _T.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.nombre,
                          style: _ts(
                            14,
                            c.unread > 0 ? FontWeight.w800 : FontWeight.w600,
                            _T.ink,
                          ),
                        ),
                        Text(
                          c.hora,
                          style: _ts(
                            11,
                            FontWeight.w500,
                            c.unread > 0 ? c.color : _T.inkSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.lastMsg,
                            style: _ts(
                              12,
                              c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                              c.unread > 0 ? _T.inkMid : _T.inkSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: c.color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${c.unread}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('💬', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Sin conversaciones', style: _ts(18, FontWeight.w800, _T.ink)),
        const SizedBox(height: 6),
        Text(
          'Agenda un paseo para chatear\ncon tu paseador',
          textAlign: TextAlign.center,
          style: _ts(13.5, FontWeight.w400, _T.inkSub, height: 1.5),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT INDIVIDUAL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatIndividualScreen extends StatefulWidget {
  final _ChatPreview chat;
  const ChatIndividualScreen({super.key, required this.chat});
  @override
  State<ChatIndividualScreen> createState() => _ChatIndividualScreenState();
}

class _ChatIndividualScreenState extends State<ChatIndividualScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _escribiendo = false;

  final List<_Mensaje> _mensajes = [
    const _Mensaje(
      'Hola! Confirmo el paseo de Max para hoy a las 4:30 PM 🐕',
      '4:20 PM',
      false,
    ),
    const _Mensaje('Perfecto Carlos, gracias por confirmar', '4:21 PM', true),
    const _Mensaje('¿Cuánto tiempo durará el paseo?', '4:21 PM', true),
    const _Mensaje(
      '45 minutos como acordamos. Lo llevaré por el parque España 🌳',
      '4:22 PM',
      false,
    ),
    const _Mensaje(
      'Excelente! Por favor manda fotos cuando puedas 📸',
      '4:23 PM',
      true,
    ),
    const _Mensaje('Claro que sí! Ya estoy en camino', '4:28 PM', false),
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _enviarMensaje() {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _mensajes.add(_Mensaje(texto, _horaActual(), true));
      _msgCtrl.clear();
      _escribiendo = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _horaActual() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.tealDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.chat.color.withOpacity(.20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.chat.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.nombre,
                  style: _ts(15, FontWeight.w800, Colors.white, spacing: -.3),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _T.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En línea',
                      style: _ts(11, FontWeight.w500, Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.phone_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Paseo activo banner
          _paseoBanner(),
          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _mensajes.length,
              itemBuilder: (_, i) => _bubbleRow(_mensajes[i], i),
            ),
          ),
          // Input
          _inputBar(),
        ],
      ),
    );
  }

  // ── PASEO BANNER ───────────────────────────────────────────────────────────
  Widget _paseoBanner() => Container(
    margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _T.tealSurface,
      borderRadius: _T.r12,
      border: Border.all(color: _T.teal.withOpacity(.20)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _T.teal.withOpacity(.15),
            borderRadius: _T.r8,
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: _T.teal,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paseo activo — Max 🐕',
                style: _ts(12.5, FontWeight.w800, _T.tealDeep),
              ),
              Text(
                'Hoy 4:30 PM · 45 min · \$25',
                style: _ts(11, FontWeight.w500, _T.teal),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _T.teal, borderRadius: _T.r8),
            child: Text(
              'Ver mapa',
              style: _ts(10.5, FontWeight.w800, Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  // ── BUBBLE ─────────────────────────────────────────────────────────────────
  Widget _bubbleRow(_Mensaje m, int i) {
    final esMio = m.esMio;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + i * 40),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: esMio
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!esMio) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.chat.color.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.chat.emoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: esMio
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: esMio ? _T.teal : _T.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(esMio ? 18 : 4),
                        bottomRight: Radius.circular(esMio ? 4 : 18),
                      ),
                      boxShadow: _T.shadow(
                        opacity: .05,
                        blur: 8,
                        offset: const Offset(0, 2),
                      ),
                    ),
                    child: Text(
                      m.texto,
                      style: _ts(
                        13.5,
                        FontWeight.w400,
                        esMio ? Colors.white : _T.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.hora, style: _ts(10, FontWeight.w400, _T.inkSub)),
                      if (esMio) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: _T.teal,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (esMio) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // ── INPUT BAR ──────────────────────────────────────────────────────────────
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _T.surface,
        boxShadow: _T.shadow(
          opacity: .06,
          blur: 20,
          offset: const Offset(0, -4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Adjuntar
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _T.tealSurface,
                  borderRadius: _T.r10,
                ),
                child: const Icon(Icons.add_rounded, color: _T.teal, size: 22),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 100,
                ),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: _T.r20,
                  border: Border.all(
                    color: _escribiendo ? _T.teal : _T.stroke,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  onChanged: (v) => setState(() => _escribiendo = v.isNotEmpty),
                  maxLines: null,
                  style: _ts(13.5, FontWeight.w400, _T.ink),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: _ts(13.5, FontWeight.w400, _T.inkSub),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _enviarMensaje,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _escribiendo ? _T.teal : _T.stroke,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _escribiendo ? Colors.white : _T.inkSub,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
