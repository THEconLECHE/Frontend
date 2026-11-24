import '../entities/chore.dart';
import '../repositories/chore_repository.dart';

class AddChore {
  const AddChore(this._repository);

  final ChoreRepository _repository;

  // Una descripcion vacia cuenta como sin descripcion
  Future<void> call(int houseId, String title, String? description, ChoreFrequency frequency, int points) {
    final trimmed = description?.trim();
    return _repository.addChore(
      houseId,
      title.trim(),
      trimmed == null || trimmed.isEmpty ? null : trimmed,
      frequency,
      points,
    );
  }
}
