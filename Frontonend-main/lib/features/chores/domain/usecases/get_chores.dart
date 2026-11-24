import '../entities/chore.dart';
import '../repositories/chore_repository.dart';

class GetChores {
  const GetChores(this._repository);

  final ChoreRepository _repository;

  Future<List<Chore>> call(int houseId) => _repository.getChores(houseId);
}
