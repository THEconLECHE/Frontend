import '../entities/board_item.dart';
import '../repositories/board_repository.dart';

class ReactToNote {
  const ReactToNote(this._repository);

  final BoardRepository _repository;

  Future<void> call(int noteId, Reaction? reaction) => _repository.react(noteId, reaction);
}
