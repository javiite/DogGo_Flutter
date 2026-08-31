import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import 'models/chat_message.dart';
import 'models/conversation_summary.dart';

class ChatRepository {
  final ChatService _service;

  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  Future<List<ChatMessage>> getMessages(int walkId) async {
    return ChatMessage.listFrom(await _service.obtenerMensajesPaseo(walkId));
  }

  Future<List<ConversationSummary>> getConversations() async {
    final results = await Future.wait<dynamic>([
      _service.obtenerConversaciones(),
      ApiService.obtenerBaseUrl(),
    ]);
    final data = results[0] as List<Map<String, dynamic>>;
    final baseUrl = results[1]?.toString();
    return data
        .map((item) => ConversationSummary.fromJson(item, baseUrl: baseUrl))
        .where((item) => item.walkId > 0)
        .toList(growable: false);
  }

  Future<void> send({
    required int walkId,
    required String content,
    String type = 'Texto',
    String? metadataJson,
    int? replyToId,
  }) async {
    await _service.enviarMensaje(
      paseoId: walkId,
      contenido: content,
      tipo: type,
      metadatosJson: metadataJson,
      respuestaAId: replyToId,
    );
  }

  Future<void> sendImage({required int walkId, required String path}) async {
    await _service.enviarImagen(paseoId: walkId, ruta: path);
  }

  Future<void> markAsRead(int walkId) {
    return _service.marcarComoLeidos(walkId);
  }
}
