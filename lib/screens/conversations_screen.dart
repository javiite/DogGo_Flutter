import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../shared/widgets/doggo_empty_view.dart';
import '../shared/widgets/doggo_error_view.dart';
import '../shared/widgets/doggo_loading_view.dart';
import '../shared/widgets/doggo_network_image.dart';
import '../shared/widgets/doggo_screen_scaffold.dart';
import '../theme/doggo_radius.dart';
import '../theme/doggo_spacing.dart';
import '../theme/doggo_theme.dart';
import 'chat/models/conversation_summary.dart';
import 'chat_paseo_screen.dart';

enum _ConversationFilter { all, active, previous }

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _service = ChatService();
  List<ConversationSummary> _items = const [];
  _ConversationFilter _filter = _ConversationFilter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        _service.obtenerConversaciones(),
        ApiService.obtenerBaseUrl(),
      ]);
      final data = results[0] as List<Map<String, dynamic>>;
      final baseUrl = results[1] as String;
      final items = data
          .map((item) => ConversationSummary.fromJson(item, baseUrl: baseUrl))
          .where((item) => item.walkId > 0)
          .toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<ConversationSummary> get _filteredItems {
    return switch (_filter) {
      _ConversationFilter.active =>
        _items.where((item) => item.isActive).toList(),
      _ConversationFilter.previous =>
        _items.where((item) => !item.isActive).toList(),
      _ConversationFilter.all => _items,
    };
  }

  Future<void> _open(ConversationSummary item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatPaseoScreen(
          paseoId: item.walkId,
          nombrePerro: item.pets,
          nombreOtroUsuario: item.otherPerson,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return DogGoScreenScaffold(title: 'Conversaciones', body: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) {
      return const DogGoLoadingView(message: 'Cargando conversaciones...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DogGoSpacing.screenHorizontal),
          child: DogGoErrorView(message: _error!, onRetry: _load),
        ),
      );
    }

    final unread = _items.fold<int>(
      0,
      (total, item) => total + item.unreadCount,
    );
    final filtered = _filteredItems;

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 380 ? 16.0 : 24.0;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 36),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConversationsHero(total: _items.length, unread: unread),
                      const SizedBox(height: DogGoSpacing.lg),
                      Text(
                        'Tus chats de paseo',
                        style: DogGoTheme.title(size: 22),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Cada conversación se mantiene vinculada al servicio correspondiente.',
                        style: DogGoTheme.subtitle(size: 12.5),
                      ),
                      const SizedBox(height: DogGoSpacing.md),
                      _ConversationFilters(
                        selected: _filter,
                        onSelected: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: DogGoSpacing.md),
                      if (filtered.isEmpty)
                        DogGoEmptyView(
                          title: _items.isEmpty
                              ? 'Todavía no hay conversaciones'
                              : 'No hay chats en este grupo',
                          message: _items.isEmpty
                              ? 'Cuando tengas una solicitud o un paseo activo podrás hablar aquí con la otra persona.'
                              : 'Cambia el filtro para consultar las demás conversaciones.',
                          icon: Icons.forum_outlined,
                          compact: true,
                        )
                      else
                        ...filtered.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ConversationCard(
                              item: item,
                              onTap: () => _open(item),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConversationsHero extends StatelessWidget {
  final int total;
  final int unread;

  const _ConversationsHero({required this.total, required this.unread});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF076858), Color(0xFF079A7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DogGoRadius.large),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(DogGoRadius.medium),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0 ? '$unread por leer' : 'Todo al día',
                  style: DogGoTheme.title(size: 20, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 1
                      ? '1 conversación de paseo'
                      : '$total conversaciones de paseo',
                  style: DogGoTheme.body(
                    size: 11.5,
                    color: Colors.white.withValues(alpha: .78),
                    weight: FontWeight.w600,
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

class _ConversationFilters extends StatelessWidget {
  final _ConversationFilter selected;
  final ValueChanged<_ConversationFilter> onSelected;

  const _ConversationFilters({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip('Todas', _ConversationFilter.all),
        _chip('Activas', _ConversationFilter.active),
        _chip('Anteriores', _ConversationFilter.previous),
      ],
    );
  }

  Widget _chip(String label, _ConversationFilter value) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
      showCheckmark: false,
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ConversationSummary item;
  final VoidCallback onTap;

  const _ConversationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.walkStatus);
    return Material(
      color: DogGoTheme.card,
      borderRadius: BorderRadius.circular(DogGoRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DogGoRadius.large),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DogGoRadius.large),
            border: Border.all(
              color: item.unreadCount > 0
                  ? DogGoTheme.teal.withValues(alpha: .38)
                  : DogGoTheme.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: DogGoNetworkImage(
                    url: item.otherPersonPhotoUrl,
                    semanticLabel: 'Foto de ${item.otherPerson}',
                    fallback: ColoredBox(
                      color: DogGoTheme.tealLight,
                      child: Center(
                        child: Text(
                          item.initials,
                          style: DogGoTheme.body(
                            size: 15,
                            color: DogGoTheme.teal,
                            weight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                            item.otherPerson,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.body(
                              size: 14,
                              color: DogGoTheme.ink,
                              weight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatActivity(item.lastActivityAt),
                          style: DogGoTheme.subtitle(size: 9.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.pets_outlined,
                          size: 15,
                          color: DogGoTheme.teal,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.pets,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.body(
                              size: 11.5,
                              color: DogGoTheme.ink,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (item.lastMessageType?.toLowerCase() ==
                            'imagen') ...[
                          const Icon(
                            Icons.photo_outlined,
                            size: 15,
                            color: DogGoTheme.muted,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            item.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DogGoTheme.subtitle(
                              size: 11,
                              color: item.unreadCount > 0
                                  ? DogGoTheme.ink
                                  : DogGoTheme.muted,
                            ),
                          ),
                        ),
                        if (item.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: const BoxDecoration(
                              color: DogGoTheme.teal,
                              borderRadius: BorderRadius.all(
                                Radius.circular(99),
                              ),
                            ),
                            child: Text(
                              item.unreadCount > 99
                                  ? '99+'
                                  : '${item.unreadCount}',
                              textAlign: TextAlign.center,
                              style: DogGoTheme.body(
                                size: 9,
                                color: Colors.white,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _ConversationTag(
                          text: item.walkStatus,
                          color: statusColor,
                        ),
                        if (item.programId != null)
                          const _ConversationTag(
                            text: 'Programación',
                            color: DogGoTheme.purple,
                            icon: Icons.event_repeat_rounded,
                          ),
                        if (item.scheduledAt != null)
                          _ConversationTag(
                            text: _formatSchedule(item.scheduledAt!),
                            color: DogGoTheme.muted,
                            icon: Icons.schedule_rounded,
                          ),
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

  static Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'encurso' => DogGoTheme.green,
      'aceptado' => DogGoTheme.teal,
      'pendiente' => DogGoTheme.orange,
      'cancelado' => DogGoTheme.red,
      _ => DogGoTheme.purple,
    };
  }

  static String _formatActivity(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(value.year, value.month, value.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return _time(value);
    if (difference == 1) return 'Ayer';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  static String _formatSchedule(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${_time(value)}';
  }

  static String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _ConversationTag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ConversationTag({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(DogGoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: DogGoTheme.body(
              size: 9.5,
              color: color,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
