import '../repositories/board_repository.dart';

class DeleteNote {
  const DeleteNote(this._repository);

  final BoardRepository _repository;

  Future<void> call(int noteId) => _repository.deleteNote(noteId);
}
