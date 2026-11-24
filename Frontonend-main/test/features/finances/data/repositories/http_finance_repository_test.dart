import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/finances/data/repositories/http_finance_repository.dart';
import 'package:flutter_roomiehub/features/finances/domain/entities/expense.dart';

void main() {
  test('expenses and debts map from the backend; each action hits its endpoint', () async {
    final sent = <String, Object?>{};
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        sent['${req.method} ${req.url.path}${req.url.hasQuery ? '?${req.url.query}' : ''}'] =
            req.body.isEmpty ? null : jsonDecode(req.body);
        return http.Response(
          jsonEncode(switch (req.url.path) {
            '/auth/login' => {
              'accessToken': 'jwt',
              'refreshToken': 'r',
              'usuario': {'id': 1, 'nombre': 'Ana'},
            },
            '/salas/7/gastos' when req.method == 'GET' => [
              {
                'id': 3,
                'concepto': 'Renta',
                'monto': '100.00',
                'moneda': 'MXN',
                'frecuencia': 'MENSUAL',
                'fechaInicio': '2026-11-01',
                'participantes': [1, 2, 3],
              },
            ],
            '/salas/7/deudas' => [
              {
                'id': 9,
                'gastoId': 3,
                'concepto': 'Renta',
                'periodo': '2026-11-01',
                'deudorId': 2,
                'deudor': null,
                'monto': '33.34',
                'moneda': 'MXN',
                'estado': 'PENDIENTE',
                'avisoPagoEn': '2026-11-02T10:00:00Z',
                'confirmadores': [1],
                'deudaOrigenId': null,
              },
            ],
            _ => {'id': 9},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await auth.login('ana@mail.com', 'x');
    final repo = HttpFinanceRepository(auth);

    final renta = (await repo.getExpenses(7)).single;
    expect(
      (renta.id, renta.concept, renta.amount, renta.currency, renta.frequency, renta.startDate),
      (3, 'Renta', '100.00', Currency.mxn, ExpenseFrequency.mensual, DateTime(2026, 11, 1)),
    );
    expect(renta.participants, [1, 2, 3]);

    final debt = (await repo.getDebts(7, DebtStatus.pendiente)).single;
    expect(sent.keys, contains('GET /salas/7/deudas?estado=PENDIENTE'));
    expect(
      (debt.id, debt.expenseId, debt.debtorId, debt.amount, debt.status),
      (9, 3, 2, '33.34', DebtStatus.pendiente),
    );
    expect(debt.confirmers, {1});
    // Un deudor que borro su cuenta no tiene nombre
    expect(debt.debtor, 'Ex miembro');
    expect(debt.notifiedAt, DateTime.utc(2026, 11, 2, 10).toLocal());

    await repo.addExpense(7, (
      concept: 'Luz',
      amount: '450.5',
      currency: Currency.usd,
      frequency: ExpenseFrequency.bimestral,
      startDate: DateTime(2026, 1, 5),
      participants: [2, 1],
    ));
    expect(sent['POST /salas/7/gastos'], {
      'concepto': 'Luz',
      // Texto y nunca double
      'monto': '450.5',
      'frecuencia': 'BIMESTRAL',
      'participantes': [2, 1],
      'moneda': 'USD',
      'fechaInicio': '2026-01-05',
    });

    await repo.editExpense(7, 3, (startDate: DateTime(2026, 1, 5), concept: 'Luz', amount: '1',
        currency: Currency.usd, frequency: ExpenseFrequency.unica, participants: [1]));
    // El backend conserva la moneda y la fecha de inicio
    expect(sent['PUT /salas/7/gastos/3'], {'concepto': 'Luz', 'monto': '1', 'frecuencia': 'UNICA', 'participantes': [1]});

    await repo.deleteExpense(7, 3);
    await repo.notifyPayment(9);
    await repo.confirmPayment(9);
    expect(sent.keys, containsAll(['DELETE /salas/7/gastos/3', 'POST /deudas/9/aviso', 'POST /deudas/9/confirmaciones']));
  });
}
