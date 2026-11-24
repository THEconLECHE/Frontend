import '../entities/expense.dart';

abstract interface class FinanceRepository {
  /* Lanza AuthException con un mensaje para el usuario
     los gastos borrados no salen */
  Future<List<Expense>> getExpenses(int houseId);

  // Solo el admin y una fecha pasada crea las deudas de los periodos ya empezados
  Future<void> addExpense(int houseId, ExpenseDraft expense);

  // Solo el admin y solo cambian los periodos futuros sin tocar moneda ni fecha
  Future<void> editExpense(int houseId, int id, ExpenseDraft expense);

  // Solo el admin y sus deudas quedan como historial
  Future<void> deleteExpense(int houseId, int id);

  // Las deudas de todos en ese estado del periodo mas nuevo al mas viejo
  Future<List<Debt>> getDebts(int houseId, DebtStatus status);

  // Solo el deudor dice que pago
  Future<void> notifyPayment(int debtId);

  // Otro participante del gasto confirma que lo recibio
  Future<void> confirmPayment(int debtId);
}
