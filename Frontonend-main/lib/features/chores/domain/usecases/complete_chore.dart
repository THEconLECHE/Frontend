import '../repositories/chore_repository.dart';

class CompleteChore {
  const CompleteChore(this._repository);

  final ChoreRepository _repository;

  Future<void> call(int id) => _repository.completeChore(id);
}
