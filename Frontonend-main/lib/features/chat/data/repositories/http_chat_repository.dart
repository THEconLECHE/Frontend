import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

/* shortcut no hay chat en vivo y los mensajes nuevos salen al abrir o enviar
   usar el STOMP del backend cuando el chat deba actualizarse solo */
class HttpChatRepository implements ChatRepository {
  const HttpChatRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<List<Message>> getMessages(int houseId) async {
    // Los ultimos 50 del mas nuevo al mas viejo
    final messages = (await _auth.request('GET', '/salas/$houseId/mensajes') as List).cast<Map<String, dynamic>>();
    return [
      for (final m in messages.reversed)
        Message(
          id: m['id'] as int,
          author: m['autor'] as String,
          // Las fotos todavia no se muestran
          text: (m['texto'] as String?) ?? '📷 Foto',
          sentAt: DateTime.parse(m['creadoEn'] as String).toLocal(),
        ),
    ];
  }

  @override
  Future<void> sendMessage(int houseId, String author, String text) =>
      _auth.request('POST', '/salas/$houseId/mensajes', {'texto': text});
}
