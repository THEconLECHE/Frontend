import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/finance_repository.dart';

/* Para tests cada casa guarda gastos y deudas en memoria como el miembro me
   los gastos nuevos no crean deudas y se pasan en debts */
class InMemoryFinanceRepository implements FinanceRepository {
  InMemoryFinanceRepository({required this.me, Map<int, List<Expense>> expenses = const {}, List<Debt> debts = const []})
    : _expenses = {for (final e in expenses.entries) e.key: [...e.value]},
      _debts = [...debts];

  final int me;
  final Map<int, List<Expense>> _expenses;
  final List<Debt> _debts;
  var _nextId = 1000;

  @override
  Future<List<Expense>> getExpenses(int houseId) async => List.unmodifiable(_expenses[houseId] ?? const []);

  @override
  Future<void> addExpense(int houseId, ExpenseDraft e) async => (_expenses[houseId] ??= []).add(
    Expense(
      id: _nextId++,
      concept: e.concept,
      amount: e.amount,
      currency: e.currency,
      frequency: e.frequency,
      startDate: e.startDate,
      participants: e.participants,
    ),
  );

  @override
  Future<void> editExpense(int houseId, int id, ExpenseDraft e) async {
    final expenses = _expenses[houseId]!;
    final i = expenses.indexWhere((x) => x.id == id);
    expenses[i] = Expense(
      id: id,
      concept: e.concept,
      amount: e.amount,
      currency: expenses[i].currency,
      frequency: e.frequency,
      startDate: expenses[i].startDate,
      participants: e.participants,
    );
  }

  @override
  Future<void> deleteExpense(int houseId, int id) async => _expenses[houseId]?.removeWhere((e) => e.id == id);

  // shortcut ignora houseId y los tests usan deudas de una sola casa
  @override
  Future<List<Debt>> getDebts(int houseId, DebtStatus status) async => _debts.where((d) => d.status == status).toList();

  @override
  Future<void> notifyPayment(int debtId) async => _update(debtId, notifiedAt: DateTime.now());

  // Como en el backend nadie confirma antes de que el deudor diga que pago
  @override
  Future<void> confirmPayment(int debtId) async {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    if (debt.notifiedAt == null) throw const AuthException('Espera a que avise que pagó para confirmarlo');
    _update(debtId, confirmers: {...debt.confirmers, me});
  }

  // Pagada cuando todos los demas participantes confirmaron
  void _update(int debtId, {DateTime? notifiedAt, Set<int>? confirmers}) {
    final i = _debts.indexWhere((d) => d.id == debtId);
    final d = _debts[i];
    final others = {
      ...?_expenses.values.expand((e) => e).where((e) => e.id == d.expenseId).firstOrNull?.participants,
    }..remove(d.debtorId);
    final when = d.notifiedAt ?? notifiedAt;
    final confirmed = confirmers ?? d.confirmers;
    final paid = others.isEmpty ? when != null : confirmed.containsAll(others);
    _debts[i] = Debt(
      id: d.id,
      expenseId: d.expenseId,
      concept: d.concept,
      period: d.period,
      debtorId: d.debtorId,
      debtor: d.debtor,
      amount: d.amount,
      currency: d.currency,
      status: paid ? DebtStatus.aprobada : d.status,
      notifiedAt: when,
      confirmers: confirmed,
    );
  }
}
