import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:flutter_roomiehub/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_roomiehub/features/finances/data/repositories/in_memory_finance_repository.dart';
import 'package:flutter_roomiehub/features/finances/domain/entities/expense.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/add_expense.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/confirm_payment.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/delete_expense.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/edit_expense.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/get_debts.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/get_expenses.dart';
import 'package:flutter_roomiehub/features/finances/domain/usecases/notify_payment.dart';
import 'package:flutter_roomiehub/features/finances/presentation/pages/finances_page.dart';
import 'package:flutter_roomiehub/features/house/domain/entities/house.dart';

// ana y Carlos reparten la renta y cada uno debe la mitad
final _renta = Expense(
  id: 3,
  concept: 'Renta',
  amount: '200.00',
  currency: Currency.mxn,
  frequency: ExpenseFrequency.mensual,
  startDate: DateTime(2026, 11, 1),
  participants: const [1, 2],
);

Debt _debt(int id, int debtorId, String debtor, {DateTime? notifiedAt, int month = 11, bool paid = false}) => Debt(
  id: id,
  expenseId: 3,
  concept: 'Renta',
  period: DateTime(2026, month, 1),
  debtorId: debtorId,
  debtor: debtor,
  amount: '100.00',
  currency: Currency.mxn,
  status: paid ? DebtStatus.aprobada : DebtStatus.pendiente,
  notifiedAt: notifiedAt,
);

void main() {
  Future<InMemoryFinanceRepository> pump(WidgetTester tester, {required bool isAdmin}) async {
    final repo = InMemoryFinanceRepository(
      me: 1,
      expenses: {1: [_renta]},
      // Octubre esta pagado y Carlos dijo que pago noviembre pero no diciembre
      debts: [
        _debt(8, 1, 'ana', month: 10, paid: true),
        _debt(9, 2, 'Carlos', month: 10, paid: true),
        _debt(10, 1, 'ana'),
        _debt(11, 2, 'Carlos', notifiedAt: DateTime(2026, 11, 2)),
        _debt(12, 2, 'Carlos', month: 12),
      ],
    );
    final auth = FakeAuthRepository();
    await auth.register('ana', 'ana@mail.com', 'secreto');
    await tester.pumpWidget(
      MaterialApp(
        home: FinancesPage(
          house: House(
            id: 1,
            name: 'Depa',
            inviteCode: 'X',
            isAdmin: isAdmin,
            members: const [
              Member(id: 1, name: 'ana', isAdmin: true),
              Member(id: 2, name: 'Carlos', isAdmin: false),
            ],
          ),
          getExpenses: GetExpenses(repo),
          addExpense: AddExpense(repo),
          editExpense: EditExpense(repo),
          deleteExpense: DeleteExpense(repo),
          getDebts: GetDebts(repo),
          notifyPayment: NotifyPayment(repo),
          confirmPayment: ConfirmPayment(repo),
          getCurrentUser: GetCurrentUser(auth),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> open(WidgetTester tester, String period) async {
    await tester.tap(find.textContaining(period, findRichText: true));
    await tester.pumpAndSettle();
  }

  Future<void> tapAndConfirm(WidgetTester tester, String button) async {
    await tester.tap(find.widgetWithText(FilledButton, button));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, button));
    await tester.pumpAndSettle();
  }

  testWidgets("One card per period with everyone's share: I say I paid mine and confirm Carlos's", (tester) async {
    await pump(tester, isAdmin: false);
    // Noviembre y diciembre con una tarjeta cada uno y octubre ya esta pagado
    expect(find.text('Renta'), findsNWidgets(2));
    expect(find.text('\$200.00 MXN · 1/11/2026 · 0/2 pagados', findRichText: true), findsOneWidget);
    expect(find.textContaining('1/10/2026', findRichText: true), findsNothing);

    await open(tester, '1/11/2026');
    expect(find.text('Total: '), findsOneWidget);
    expect(find.text('ana (tú)'), findsOneWidget);
    // La mia la pago yo y la de Carlos la confirmo porque ya dijo que pago
    expect(find.widgetWithText(FilledButton, 'Ya pagué'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirmar'), findsOneWidget);

    await tapAndConfirm(tester, 'Ya pagué');
    await open(tester, '1/11/2026');
    // Basta decirlo una vez y Carlos aun debe confirmar
    expect(find.widgetWithText(FilledButton, 'Ya pagué'), findsNothing);
    expect(find.textContaining('Avisó · confirmado 0/1', findRichText: true), findsNWidgets(2));
    expect(find.textContaining('Falta: Carlos', findRichText: true), findsOneWidget);

    await tapAndConfirm(tester, 'Confirmar');
    expect(find.text('\$200.00 MXN · 1/11/2026 · 1/2 pagados', findRichText: true), findsOneWidget);

    // En diciembre Carlos no ha dicho que pago y no hay nada que confirmar
    await open(tester, '1/12/2026');
    expect(find.byType(FilledButton), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pagadas'));
    await tester.pumpAndSettle();
    expect(find.text('\$200.00 MXN · 1/10/2026 · Pagado', findRichText: true), findsOneWidget);
    expect(find.textContaining('1/11/2026', findRichText: true), findsNothing);

    // Solo el admin maneja gastos
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    expect(find.text('Renta'), findsOneWidget);
    expect(find.text('Nuevo gasto'), findsNothing);
    expect(find.byTooltip('Eliminar'), findsNothing);
  });

  testWidgets('The admin adds, edits and deletes an expense', (tester) async {
    final repo = await pump(tester, isAdmin: true);
    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el concepto'), findsOneWidget);
    expect(find.text('Monto con hasta 2 decimales'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Concepto'), '  Internet ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Monto total'), '0');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('Mayor que cero'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Monto total'), '499,9');
    // Carlos no lo usa
    await tester.tap(find.widgetWithText(FilterChip, 'Carlos'));
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(find.text('\$499.9 MXN · Mensual · entre 1'), findsOneWidget);
    final internet = (await repo.getExpenses(1)).last;
    expect(internet.concept, 'Internet');
    expect(internet.participants, [1]);

    // Un gasto recurrente no puede volverse unico
    await tester.tap(find.text('Internet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual').last);
    await tester.pumpAndSettle();
    expect(find.text('Único'), findsNothing);
    await tester.tap(find.text('Bimestral').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('\$499.9 MXN · Bimestral · entre 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Internet'), findsNothing);
    expect(find.text('Renta'), findsOneWidget);
  });
}
