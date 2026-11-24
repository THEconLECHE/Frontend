import '../repositories/finance_repository.dart';

class DeleteExpense {
  const DeleteExpense(this._repository);

  final FinanceRepository _repository;

  Future<void> call(int houseId, int id) => _repository.deleteExpense(houseId, id);
}
