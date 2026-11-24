import '../entities/expense.dart';
import '../repositories/finance_repository.dart';

class AddExpense {
  const AddExpense(this._repository);

  final FinanceRepository _repository;

  Future<void> call(int houseId, ExpenseDraft expense) =>
      _repository.addExpense(houseId, (
        concept: expense.concept.trim(),
        amount: expense.amount.trim(),
        currency: expense.currency,
        frequency: expense.frequency,
        startDate: expense.startDate,
        participants: expense.participants,
      ));
}
