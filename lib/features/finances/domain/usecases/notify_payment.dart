import '../repositories/finance_repository.dart';

class NotifyPayment {
  const NotifyPayment(this._repository);

  final FinanceRepository _repository;

  Future<void> call(int debtId) => _repository.notifyPayment(debtId);
}
