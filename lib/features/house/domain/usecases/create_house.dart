import '../repositories/house_repository.dart';

class CreateHouse {
  const CreateHouse(this._repository);

  final HouseRepository _repository;

  Future<void> call(String name) => _repository.create(name.trim());
}
