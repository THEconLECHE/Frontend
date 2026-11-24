import '../repositories/profile_repository.dart';

class EditName {
  const EditName(this._repository);

  final ProfileRepository _repository;

  Future<void> call(String name) => _repository.editName(name);
}
