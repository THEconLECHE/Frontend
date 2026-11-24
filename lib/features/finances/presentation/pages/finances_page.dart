import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../house/domain/entities/house.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/confirm_payment.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/edit_expense.dart';
import '../../domain/usecases/get_debts.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/notify_payment.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/expense_dialog.dart';

enum _View { pending, paid, expenses }

class FinancesPage extends StatefulWidget {
  const FinancesPage({
    super.key,
    required this.house,
    required this.getExpenses,
    required this.addExpense,
    required this.editExpense,
    required this.deleteExpense,
    required this.getDebts,
    required this.notifyPayment,
    required this.confirmPayment,
    required this.getCurrentUser,
  });

  // Sus miembros son con quien se reparte un gasto y solo el admin maneja gastos
  final House house;
  final GetExpenses getExpenses;
  final AddExpense addExpense;
  final EditExpense editExpense;
  final DeleteExpense deleteExpense;
  final GetDebts getDebts;
  final NotifyPayment notifyPayment;
  final ConfirmPayment confirmPayment;
  final GetCurrentUser getCurrentUser;

  @override
  State<FinancesPage> createState() => _FinancesPageState();
}

class _FinancesPageState extends State<FinancesPage> {
  // null mientras carga la primera vez
  List<Expense>? _expenses;
  List<Debt>? _pending;
  List<Debt>? _paid;
  var _view = _View.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _run(() async {
    // Una tras otra porque wait envuelve el AuthException y _run no lo veria
    final expenses = await widget.getExpenses(widget.house.id);
    final pending = await widget.getDebts(widget.house.id, DebtStatus.pendiente);
    final paid = await widget.getDebts(widget.house.id, DebtStatus.aprobada);
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _pending = pending;
        _paid = paid;
      });
    }
  });

  Future<void> _add() async {
    final expense = await showDialog<ExpenseDraft>(
      context: context,
      builder: (_) => ExpenseDialog(members: widget.house.members),
    );
    if (expense == null) return;
    await _run(() async {
      await widget.addExpense(widget.house.id, expense);
      _show('Gasto creado. Sus deudas aparecen al iniciar cada periodo');
      await _load();
    });
  }

  Future<void> _edit(Expense initial) async {
    final expense = await showDialog<ExpenseDraft>(
      context: context,
      builder: (_) => ExpenseDialog(members: widget.house.members, initial: initial),
    );
    if (expense == null) return;
    await _run(() async {
      await widget.editExpense(widget.house.id, initial.id, expense);
      _show('Gasto actualizado. Aplica desde el siguiente periodo');
      await _load();
    });
  }

  Future<void> _delete(Expense expense) async {
    final ok = await confirm(
      context,
      'Eliminar gasto',
      '«${expense.concept}» dejará de generar deudas. Las que ya existen quedan como historial.',
      'Eliminar',
    );
    if (!ok) return;
    await _run(() async {
      await widget.deleteExpense(widget.house.id, expense.id);
      await _load();
    });
  }

  Future<void> _notify(Debt debt) async {
    final ok = await confirm(
      context,
      'Avisar pago',
      '¿Ya pagaste ${formatMoney(debt.amount, debt.currency)} de «${debt.concept}»? Los demás confirmarán que lo recibieron.',
      'Ya pagué',
    );
    if (!ok) return;
    await _run(() async {
      await widget.notifyPayment(debt.id);
      await _load();
    });
  }

  Future<void> _confirm(Debt debt) async {
    final ok = await confirm(
      context,
      'Confirmar pago',
      '¿Recibiste el pago de ${debt.debtor} por ${formatMoney(debt.amount, debt.currency)}?',
      'Confirmar',
    );
    if (!ok) return;
    await _run(() async {
      await widget.confirmPayment(debt.id);
      await _load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      _show(e.message);
    }
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    /* shortcut el usuario se busca por nombre y dos roomies con el mismo nombre se confunden
       usar usuarioId cuando la sesion guarde el id */
    final me = widget.getCurrentUser();
    final meId = widget.house.members.where((m) => m.name == me).firstOrNull?.id;
    // Los gastos borrados no salen y sus deudas se ven pero ya no aceptan pagos
    final expenses = {for (final e in _expenses ?? const <Expense>[]) e.id: e};
    /* Una tarjeta por gasto y periodo con la parte de cada quien
       sigue pendiente mientras alguien no pague */
    final shares = <(int, DateTime), List<Debt>>{};
    for (final d in [...?_pending, ...?_paid]) {
      (shares[(d.expenseId, d.period)] ??= []).add(d);
    }
    final payments = _pending == null
        ? null
        : ([
            for (final debts in shares.values)
              if (debts.every((d) => d.status == DebtStatus.aprobada) == (_view == _View.paid))
                (concept: debts.first.concept, period: debts.first.period, debts: debts),
          ]..sort((a, b) => b.period.compareTo(a.period)));

    return Scaffold(
      floatingActionButton: widget.house.isAdmin && _view == _View.expenses
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo gasto'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
          children: [
            const PageTitle('Finanzas'),
            const SizedBox(height: 16),
            SegmentedButton<_View>(
              segments: const [
                ButtonSegment(value: _View.pending, label: Text('Pendientes'), icon: Icon(Icons.schedule)),
                ButtonSegment(value: _View.paid, label: Text('Pagadas'), icon: Icon(Icons.done_all)),
                ButtonSegment(value: _View.expenses, label: Text('Gastos'), icon: Icon(Icons.receipt_long_outlined)),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
            const SizedBox(height: 16),
            if (_view == _View.expenses) ...[
              if (_expenses case final expenses? when expenses.isEmpty)
                const _Empty('No hay gastos compartidos'),
              for (final expense in _expenses ?? const <Expense>[])
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: widget.house.isAdmin ? () => _edit(expense) : null,
                    leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                    title: Text(expense.concept, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${formatMoney(expense.amount, expense.currency)} · ${expense.frequency.label} · '
                      'entre ${expense.participants.length}',
                    ),
                    trailing: widget.house.isAdmin
                        ? IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(expense),
                          )
                        : null,
                  ),
                ),
            ] else ...[
              if (payments != null && payments.isEmpty)
                _Empty(_view == _View.paid ? 'Aún no hay pagos completos' : 'Nadie debe nada. ¡Cuentas claras!'),
              for (final payment in payments ?? const <Payment>[])
                _PaymentCard(
                  payment,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => PaymentDialog(
                      payment,
                      expense: expenses[payment.debts.first.expenseId],
                      members: widget.house.members,
                      meId: meId,
                      onNotify: _notify,
                      onConfirm: _confirm,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(top: 48), child: Center(child: Text(text)));
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard(this.payment, {required this.onTap});

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = paymentStatus(payment);
    final total = formatMoney(sumAmounts(payment.debts.map((d) => d.amount)), payment.debts.first.currency);
    return Card(
      clipBehavior: Clip.antiAlias,
      // Al tocarla se abren las partes de todos para decir que pagaste o confirmar
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
        title: Text(payment.concept, style: const TextStyle(fontWeight: FontWeight.w600)),
        // La etiqueta tambien dice el estado para quien no distingue colores
        trailing: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
        ),
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$total · ${formatDate(payment.period)}'),
              TextSpan(
                text: ' · ${status.label}',
                style: TextStyle(color: status.color.shade800, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
