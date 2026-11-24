import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

// Para tests cada casa guarda sus mensajes en memoria sin backend
class InMemoryChatRepository implements ChatRepository {
  final _messages = <int, List<Message>>{};
  var _nextId = 1;

  @override
  Future<List<Message>> getMessages(int houseId) async => List.unmodifiable(_messages[houseId] ?? const []);

  @override
  Future<void> sendMessage(int houseId, String author, String text) async =>
      (_messages[houseId] ??= []).add(Message(id: _nextId++, author: author, text: text, sentAt: DateTime.now()));
}
