import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/finance_repository.dart';

class HttpFinanceRepository implements FinanceRepository {
  const HttpFinanceRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<List<Expense>> getExpenses(int houseId) async => [
    for (final g in (await _auth.request('GET', '/salas/$houseId/gastos') as List).cast<Map<String, dynamic>>())
      Expense(
        id: g['id'] as int,
        concept: g['concepto'] as String,
        amount: g['monto'] as String,
        currency: Currency.values.byName((g['moneda'] as String).toLowerCase()),
        frequency: ExpenseFrequency.values.byName((g['frecuencia'] as String).toLowerCase()),
        startDate: DateTime.parse(g['fechaInicio'] as String),
        participants: (g['participantes'] as List).cast<int>(),
      ),
  ];

  @override
  Future<void> addExpense(int houseId, ExpenseDraft expense) => _auth.request('POST', '/salas/$houseId/gastos', {
    ..._body(expense),
    'moneda': expense.currency.name.toUpperCase(),
    // Fecha en formato yyyy MM dd
    'fechaInicio': expense.startDate.toIso8601String().substring(0, 10),
  });

  @override
  Future<void> editExpense(int houseId, int id, ExpenseDraft expense) =>
      _auth.request('PUT', '/salas/$houseId/gastos/$id', _body(expense));

  // Los montos viajan como texto para no perder centavos
  static Map<String, Object?> _body(ExpenseDraft expense) => {
    'concepto': expense.concept,
    'monto': expense.amount,
    'frecuencia': expense.frequency.name.toUpperCase(),
    'participantes': expense.participants,
  };

  @override
  Future<void> deleteExpense(int houseId, int id) => _auth.request('DELETE', '/salas/$houseId/gastos/$id');

  @override
  Future<List<Debt>> getDebts(int houseId, DebtStatus status) async => [
    for (final d
        in (await _auth.request('GET', '/salas/$houseId/deudas?estado=${status.name.toUpperCase()}') as List)
            .cast<Map<String, dynamic>>())
      Debt(
        id: d['id'] as int,
        expenseId: d['gastoId'] as int,
        concept: d['concepto'] as String,
        period: DateTime.parse(d['periodo'] as String),
        debtorId: d['deudorId'] as int,
        // null si el deudor borro su cuenta
        debtor: d['deudor'] as String? ?? 'Ex miembro',
        amount: d['monto'] as String,
        currency: Currency.values.byName((d['moneda'] as String).toLowerCase()),
        status: DebtStatus.values.byName((d['estado'] as String).toLowerCase()),
        notifiedAt: d['avisoPagoEn'] == null ? null : DateTime.parse(d['avisoPagoEn'] as String).toLocal(),
        confirmers: {...(d['confirmadores'] as List).cast<int>()},
      ),
  ];

  @override
  Future<void> notifyPayment(int debtId) => _auth.request('POST', '/deudas/$debtId/aviso');

  @override
  Future<void> confirmPayment(int debtId) => _auth.request('POST', '/deudas/$debtId/confirmaciones');
}
