import '../repositories/house_repository.dart';

class LeaveHouse {
  const LeaveHouse(this._repository);

  final HouseRepository _repository;

  Future<void> call(int houseId) => _repository.leave(houseId);
}
