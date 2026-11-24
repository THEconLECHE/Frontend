import '../repositories/house_repository.dart';

class GetHouses {
  const GetHouses(this._repository);

  final HouseRepository _repository;

  Future<List<({int id, String name})>> call() => _repository.getHouses();
}
