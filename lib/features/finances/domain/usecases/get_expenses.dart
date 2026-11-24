import '../entities/expense.dart';
import '../repositories/finance_repository.dart';

class GetExpenses {
  const GetExpenses(this._repository);

  final FinanceRepository _repository;

  Future<List<Expense>> call(int houseId) => _repository.getExpenses(houseId);
}
