import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/session_service.dart';
import '../services/storage_service.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import '../widgets/doggo_logo.dart';
import 'chat/chat_controller.dart';
import 'chat/chat_state.dart';
import 'chat/models/chat_message.dart';

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

class _ChatPaseoScreenState extends State<ChatPaseoScreen>
    with WidgetsBindingObserver {
  late final ChatController _controller;

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final FocusNode _focusNode = FocusNode();

  int _lastRevision = -1;
  int _lastMessageCount = 0;
  int _pendingNewMessages = 0;

  bool _forceScrollToBottom = false;
  bool _roleReady = false;
  bool _isWalker = false;
  ChatMessage? _replyTo;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _controller = ChatController(walkId: widget.paseoId);

    _scrollController.addListener(_handleScroll);

    _controller.initialize();
    SessionService.esPaseador().then((value) {
      if (!mounted) return;
      setState(() {
        _isWalker = value;
        _roleReady = true;
      });
    });
    StorageService.obtenerBaseUrl().then((value) {
      if (mounted) setState(() => _baseUrl = value);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _messageController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    _focusNode.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.loadMessages(silent: true);
    }
  }

  void _handleScroll() {
    if (_isNearBottom && _pendingNewMessages > 0) {
      setState(() {
        _pendingNewMessages = 0;
      });
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;

    return position.maxScrollExtent - position.pixels < 140;
  }

  void _processMessageUpdate(ChatState state) {
    if (_lastRevision == state.revision) {
      return;
    }

    final newMessages = state.messageCount - _lastMessageCount;

    final shouldMoveToBottom =
        _lastRevision < 0 ||
        _lastMessageCount == 0 ||
        _forceScrollToBottom ||
        _isNearBottom;

    _lastRevision = state.revision;
    _lastMessageCount = state.messageCount;

    if (shouldMoveToBottom) {
      _forceScrollToBottom = false;
      _pendingNewMessages = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else if (newMessages > 0) {
      _pendingNewMessages += newMessages;
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );

    if (_pendingNewMessages > 0 && mounted) {
      setState(() {
        _pendingNewMessages = 0;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _forceScrollToBottom = true;

    final result = await _controller.send(text, replyToId: _replyTo?.id);

    if (!mounted) {
      return;
    }

    if (result.success) {
      _messageController.clear();
      setState(() => _replyTo = null);
      _focusNode.requestFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      return;
    }

    _forceScrollToBottom = false;
    _showMessage(result.message);
  }

  Future<void> _sendQuick(String text) async {
    _forceScrollToBottom = true;
    final result = await _controller.send(text, type: 'Rapido');
    if (!mounted) return;
    if (!result.success) _showMessage(result.message);
  }

  Future<void> _sendPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar fotografía'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    final result = await _controller.sendImage(image.path);
    if (!mounted) return;
    _showMessage(result.message, success: result.success);
  }

  Future<void> _showMessageOptions(ChatMessage message) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copiar mensaje'),
                  onTap: () => Navigator.pop(sheetContext, 'copy'),
                ),
                if (message.id != null)
                  ListTile(
                    leading: const Icon(Icons.reply_rounded),
                    title: const Text('Responder'),
                    onTap: () => Navigator.pop(sheetContext, 'reply'),
                  ),
                if (message.fullDateLabel.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Fecha y hora'),
                    subtitle: Text(message.fullDateLabel),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.content));

      if (mounted) {
        _showMessage('Mensaje copiado.', success: true);
      }
    } else if (action == 'reply' && mounted) {
      setState(() => _replyTo = message);
      _focusNode.requestFocus();
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? DogGoTheme.teal : DogGoTheme.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;

        _processMessageUpdate(state);

        return Scaffold(
          backgroundColor: DogGoTheme.cream,
          body: SafeArea(
            child: Column(
              children: [
                _ChatTopBar(
                  messageCount: state.messageCount,
                  refreshing: state.refreshing,
                  onRefresh: _controller.refresh,
                ),
                _ConversationHeader(
                  petName: widget.nombrePerro,
                  otherUserName: widget.nombreOtroUsuario,
                ),
                if (state.backgroundError != null)
                  _BackgroundErrorBanner(
                    message: state.backgroundError!,
                    onRetry: () => _controller.loadMessages(silent: true),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildConversation(state)),
                      if (_pendingNewMessages > 0)
                        Positioned(
                          right: 16,
                          bottom: 14,
                          child: _NewMessagesButton(
                            count: _pendingNewMessages,
                            onTap: _scrollToBottom,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_roleReady)
                  _QuickReplies(
                    isWalker: _isWalker,
                    onSelected: _sendQuick,
                    enabled: !state.sending,
                  ),
                _MessageComposer(
                  controller: _messageController,
                  focusNode: _focusNode,
                  sending: state.sending,
                  replyTo: _replyTo,
                  onCancelReply: () => setState(() => _replyTo = null),
                  onPhoto: _sendPhoto,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversation(ChatState state) {
    if (state.loading) {
      return const DogGoLoadingView(message: 'Cargando conversación...');
    }

    if (state.error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
        child: DogGoErrorView(
          title: 'No pudimos cargar el chat',
          message: state.error!,
          icon: Icons.forum_outlined,
          onRetry: _controller.refresh,
        ),
      );
    }

    if (state.messages.isEmpty) {
      return _EmptyConversation(
        otherUserName: widget.nombreOtroUsuario,
        onWrite: () {
          _focusNode.requestFocus();
        },
        onRefresh: _controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: DogGoTheme.teal,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: state.messages.length,
        itemBuilder: (context, index) {
          final message = state.messages[index];
          final mine = state.isMine(message);

          return Column(
            children: [
              if (state.shouldShowDateSeparator(index))
                _DateSeparator(text: message.dayLabel),
              if (message.systemMessage)
                _SystemMessage(message: message)
              else
                _MessageBubble(
                  message: message,
                  mine: mine,
                  mediaUrl: _mediaUrl(message.mediaUrl),
                  onLongPress: () => _showMessageOptions(message),
                ),
            ],
          );
        },
      ),
    );
  }

  String? _mediaUrl(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = _baseUrl?.replaceAll(RegExp(r'/+$'), '') ?? '';
    return base.isEmpty
        ? value
        : '$base/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }
}

class _ChatTopBar extends StatelessWidget {
  final int messageCount;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _ChatTopBar({
    required this.messageCount,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: DogGoTheme.card,
        border: Border(bottom: BorderSide(color: DogGoTheme.border)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Regresar',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 5),
          const DogGoLogo(size: 37),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat del paseo', style: DogGoTheme.title(size: 17)),
                Text(
                  messageCount == 1 ? '1 mensaje' : '$messageCount mensajes',
                  style: DogGoTheme.caption(size: 10),
                ),
              ],
            ),
          ),
          if (refreshing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  final String petName;
  final String otherUserName;

  const _ConversationHeader({
    required this.petName,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: DogGoTheme.cream,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          borderRadius: BorderRadius.circular(DogGoRadius.large),
          border: Border.all(color: DogGoTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: DogGoTheme.teal,
                borderRadius: BorderRadius.circular(DogGoRadius.medium),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.title(size: 17),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Conversación con $otherUserName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.subtitle(size: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: DogGoTheme.greenLight,
                borderRadius: BorderRadius.circular(DogGoRadius.pill),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: DogGoTheme.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Actualización automática',
                    style: DogGoTheme.caption(
                      size: 8.5,
                      color: DogGoTheme.green,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BackgroundErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: DogGoTheme.orangeLight,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: DogGoTheme.orange,
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No se pudo actualizar. '
              'La conversación anterior sigue visible.',
              style: DogGoTheme.caption(
                size: 9.5,
                color: DogGoTheme.orange,
                weight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final String otherUserName;
  final VoidCallback onWrite;
  final Future<void> Function() onRefresh;

  const _EmptyConversation({
    required this.otherUserName,
    required this.onWrite,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: DogGoTheme.teal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              color: DogGoTheme.card,
              borderRadius: BorderRadius.circular(DogGoRadius.extraLarge),
              border: Border.all(color: DogGoTheme.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: DogGoTheme.tealLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    color: DogGoTheme.teal,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Inicia la conversación',
                  textAlign: TextAlign.center,
                  style: DogGoTheme.title(size: 20),
                ),
                const SizedBox(height: 7),
                Text(
                  'Escribe a $otherUserName para coordinar el horario, la recogida o cualquier indicación del paseo.',
                  textAlign: TextAlign.center,
                  style: DogGoTheme.subtitle(size: 12.5),
                ),
                const SizedBox(height: 17),
                ElevatedButton.icon(
                  onPressed: onWrite,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Escribir mensaje'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final String? mediaUrl;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.mediaUrl,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: mine
          ? 'Tu mensaje: ${message.content}. ${message.timeLabel}'
          : 'Mensaje de ${message.senderName}: ${message.content}. ${message.timeLabel}',
      hint: 'Mantén presionado para ver opciones',
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .78,
            ),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
            decoration: BoxDecoration(
              color: mine ? DogGoTheme.teal : DogGoTheme.card,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(21),
                topRight: const Radius.circular(21),
                bottomLeft: Radius.circular(mine ? 21 : 6),
                bottomRight: Radius.circular(mine ? 6 : 21),
              ),
              border: mine ? null : Border.all(color: DogGoTheme.border),
              boxShadow: DogGoTheme.softShadow(
                opacity: .025,
                blur: 12,
                offset: const Offset(0, 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!mine) ...[
                  Text(
                    message.senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DogGoTheme.caption(
                      size: 9.5,
                      color: DogGoTheme.teal,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (message.replyToId != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: mine
                          ? Colors.white.withValues(alpha: .13)
                          : DogGoTheme.tealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Respuesta a un mensaje anterior',
                      style: DogGoTheme.caption(
                        size: 9.5,
                        color: mine ? Colors.white : DogGoTheme.teal,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (message.isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 230,
                      height: 180,
                      child: DogGoNetworkImage(
                        url: mediaUrl,
                        semanticLabel: 'Fotografía compartida en el chat',
                        fallback: Container(
                          color: DogGoTheme.tealLight,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                if (message.content.isNotEmpty) ...[
                  if (message.isImage) const SizedBox(height: 7),
                  Text(
                    message.content,
                    style: DogGoTheme.body(
                      size: 13.5,
                      color: mine ? Colors.white : DogGoTheme.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timeLabel,
                      style: DogGoTheme.caption(
                        size: 9,
                        color: mine
                            ? Colors.white.withValues(alpha: .7)
                            : DogGoTheme.muted,
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.read
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: .72),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final ChatMessage message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: DogGoTheme.purpleLight,
        borderRadius: BorderRadius.circular(DogGoRadius.medium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: DogGoTheme.purple,
            size: 16,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              message.content,
              textAlign: TextAlign.center,
              style: DogGoTheme.caption(
                size: 10,
                color: DogGoTheme.purple,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String text;

  const _DateSeparator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: DogGoTheme.card,
            borderRadius: BorderRadius.circular(DogGoRadius.pill),
            border: Border.all(color: DogGoTheme.border),
          ),
          child: Text(text, style: DogGoTheme.caption(size: 9.5)),
        ),
      ),
    );
  }
}

class _NewMessagesButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NewMessagesButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DogGoTheme.teal,
      borderRadius: BorderRadius.circular(DogGoRadius.pill),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                count == 1 ? '1 mensaje nuevo' : '$count mensajes nuevos',
                style: DogGoTheme.caption(
                  size: 10,
                  color: Colors.white,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final ChatMessage? replyTo;
  final VoidCallback onCancelReply;
  final VoidCallback onPhoto;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.replyTo,
    required this.onCancelReply,
    required this.onPhoto,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
        decoration: BoxDecoration(
          color: DogGoTheme.card,
          border: const Border(top: BorderSide(color: DogGoTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(11, 7, 4, 7),
                decoration: BoxDecoration(
                  color: DogGoTheme.tealLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 18,
                      color: DogGoTheme.teal,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        replyTo!.content.isEmpty
                            ? 'Responder a la fotografía'
                            : replyTo!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DogGoTheme.caption(
                          size: 10.5,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onCancelReply,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final text = value.text.trim();
                final canSend = text.isNotEmpty && !sending;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton.filledTonal(
                      onPressed: sending ? null : onPhoto,
                      tooltip: 'Enviar fotografía',
                      icon: const Icon(Icons.add_a_photo_outlined),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: !sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: ChatController.maximumMessageLength,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          counterText: '',
                          prefixIcon: Icon(Icons.message_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Semantics(
                      button: true,
                      label: sending ? 'Enviando mensaje' : 'Enviar mensaje',
                      child: SizedBox(
                        width: 51,
                        height: 51,
                        child: ElevatedButton(
                          onPressed: canSend ? onSend : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(51, 51),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DogGoRadius.medium,
                              ),
                            ),
                          ),
                          child: sending
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
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final ValueChanged<String> onSelected;
  final bool enabled;
  final bool isWalker;

  const _QuickReplies({
    required this.onSelected,
    required this.enabled,
    required this.isWalker,
  });

  @override
  Widget build(BuildContext context) {
    final options = isWalker
        ? const [
            'Ya llegué',
            'Recogida lista',
            'Iniciamos',
            'Todo bien',
            'Terminamos',
          ]
        : const [
            'Ya voy',
            'Te espero en la entrada',
            '¿Cómo va?',
            'Avísame al llegar',
            'Gracias',
          ];
    return Container(
      height: 46,
      color: DogGoTheme.card,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) => ActionChip(
          avatar: const Icon(
            Icons.bolt_rounded,
            size: 16,
            color: DogGoTheme.teal,
          ),
          label: Text(options[index]),
          onPressed: enabled ? () => onSelected(options[index]) : null,
        ),
      ),
    );
  }
}
