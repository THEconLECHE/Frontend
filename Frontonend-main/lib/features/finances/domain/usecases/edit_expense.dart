import '../entities/expense.dart';
import '../repositories/finance_repository.dart';

class EditExpense {
  const EditExpense(this._repository);

  final FinanceRepository _repository;

  Future<void> call(int houseId, int id, ExpenseDraft expense) => _repository.editExpense(houseId, id, expense);
}
