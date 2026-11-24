import '../repositories/board_repository.dart';

class AddNote {
  const AddNote(this._repository);

  final BoardRepository _repository;

  Future<void> call(int houseId, String title, List<String> lines) => _repository.addNote(houseId, title, lines);
}
