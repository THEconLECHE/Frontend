import '../repositories/house_repository.dart';

class ExpelMember {
  const ExpelMember(this._repository);

  final HouseRepository _repository;

  Future<void> call(int houseId, int userId) => _repository.expel(houseId, userId);
}
