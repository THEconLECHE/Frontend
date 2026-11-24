import '../repositories/board_repository.dart';

class PinNote {
  const PinNote(this._repository);

  final BoardRepository _repository;

  Future<void> call(int noteId, bool pinned) => _repository.setPinned(noteId, pinned);
}
