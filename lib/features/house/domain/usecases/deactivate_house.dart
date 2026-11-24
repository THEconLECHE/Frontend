import '../repositories/house_repository.dart';

class DeactivateHouse {
  const DeactivateHouse(this._repository);

  final HouseRepository _repository;

  Future<void> call(int houseId) => _repository.deactivate(houseId);
}
