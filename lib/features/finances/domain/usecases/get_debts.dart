import '../entities/expense.dart';
import '../repositories/finance_repository.dart';

class GetDebts {
  const GetDebts(this._repository);

  final FinanceRepository _repository;

  Future<List<Debt>> call(int houseId, DebtStatus status) => _repository.getDebts(houseId, status);
}
