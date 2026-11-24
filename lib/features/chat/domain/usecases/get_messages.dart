import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class GetMessages {
  const GetMessages(this._repository);

  final ChatRepository _repository;

  Future<List<Message>> call(int houseId) => _repository.getMessages(houseId);
}
