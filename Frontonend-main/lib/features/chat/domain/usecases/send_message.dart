import '../repositories/chat_repository.dart';

class SendMessage {
  const SendMessage(this._repository);

  // El mismo limite de texto que pone el backend
  static const maxLength = 4000;

  final ChatRepository _repository;

  // Los mensajes vacios se ignoran
  Future<void> call(int houseId, String author, String text) async {
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) await _repository.sendMessage(houseId, author, trimmed);
  }
}
