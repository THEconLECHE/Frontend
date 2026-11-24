import '../repositories/house_repository.dart';

class SelectHouse {
  const SelectHouse(this._repository);

  final HouseRepository _repository;

  void call(int houseId) => _repository.select(houseId);
}
