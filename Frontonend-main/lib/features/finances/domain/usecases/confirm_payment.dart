import '../repositories/finance_repository.dart';

class ConfirmPayment {
  const ConfirmPayment(this._repository);

  final FinanceRepository _repository;

  Future<void> call(int debtId) => _repository.confirmPayment(debtId);
}
