import '../entities/message.dart';

abstract interface class ChatRepository {
  // Del mas viejo al mas nuevo y lanza AuthException con un mensaje para el usuario
  Future<List<Message>> getMessages(int houseId);

  // author es el nombre de quien envia y el backend lo toma de la sesion
  Future<void> sendMessage(int houseId, String author, String text);
}
