import '../repositories/house_repository.dart';

class TransferAdmin {
  const TransferAdmin(this._repository);

  final HouseRepository _repository;

  Future<void> call(int houseId, int userId) => _repository.transferAdmin(houseId, userId);
}
