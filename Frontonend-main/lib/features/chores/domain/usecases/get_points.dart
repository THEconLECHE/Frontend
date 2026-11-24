import '../repositories/chore_repository.dart';

class GetPoints {
  const GetPoints(this._repository);

  final ChoreRepository _repository;

  Future<Map<String, int>> call(int houseId) => _repository.getPoints(houseId);
}
