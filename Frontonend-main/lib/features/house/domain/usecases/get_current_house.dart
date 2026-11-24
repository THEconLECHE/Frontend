import '../entities/house.dart';
import '../repositories/house_repository.dart';

class GetCurrentHouse {
  const GetCurrentHouse(this._repository);

  final HouseRepository _repository;

  Future<House?> call() => _repository.getCurrentHouse();
}
