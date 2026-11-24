import '../repositories/house_repository.dart';

class JoinHouse {
  const JoinHouse(this._repository);

  final HouseRepository _repository;

  Future<void> call(String code) => _repository.join(code.trim().toUpperCase());
}
