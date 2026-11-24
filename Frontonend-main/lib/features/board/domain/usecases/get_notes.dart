import '../entities/board_item.dart';
import '../repositories/board_repository.dart';

class GetNotes {
  const GetNotes(this._repository);

  final BoardRepository _repository;

  Future<List<BoardItem>> call(int houseId) => _repository.getItems(houseId);
}
