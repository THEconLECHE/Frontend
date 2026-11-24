import 'package:flutter/material.dart';

import '../../../../core/widgets/member_avatar.dart';
import '../../../../core/widgets/slide_to_confirm.dart';
import '../../../house/domain/entities/house.dart';
import '../../domain/entities/expense.dart';
import 'expense_dialog.dart';

// Un periodo de un gasto con la parte de cada participante
typedef Payment = ({String concept, DateTime period, List<Debt> debts});

// Suma textos decimales en centavos para no perder nada
String sumAmounts(Iterable<String> amounts) {
  final cents = amounts.fold(0, (total, a) => total + (double.parse(a) * 100).round());
  return '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
}

// Verde si todos pagaron amarillo si alguien pago o lo dijo rojo si nadie
({MaterialColor color, String label}) paymentStatus(Payment payment) {
  final paid = payment.debts.where((d) => d.status == DebtStatus.aprobada).length;
  final total = payment.debts.length;
  if (paid == total) return (color: Colors.green, label: 'Pagado');
  final started = paid > 0 || payment.debts.any((d) => d.notifiedAt != null);
  return (color: started ? Colors.amber : Colors.red, label: '$paid/$total pagados');
}

// Una parte rojo sin pagar amarillo esperando confirmar verde pagada
({MaterialColor color, String label}) debtStatus(Debt debt, int? others) => switch (debt.status) {
  DebtStatus.aprobada => (color: Colors.green, label: 'Pagado'),
  DebtStatus.repartida => (color: Colors.grey, label: 'Repartido'),
  DebtStatus.pendiente when debt.notifiedAt == null => (color: Colors.red, label: 'Sin pagar'),
  _ => (color: Colors.amber, label: others == null ? 'Por confirmar' : 'Avisó · confirmado ${debt.confirmers.length}/$others'),
};

/* Todos los datos de un periodo de un gasto al tocarlo en la lista
   mi parte tiene el boton de ya pague y las otras el boton de confirmar */
class PaymentDialog extends StatelessWidget {
  const PaymentDialog(
    this.payment, {
    super.key,
    this.expense,
    required this.members,
    required this.meId,
    required this.onNotify,
    required this.onConfirm,
  });

  final Payment payment;
  // null si el gasto se borro y sus deudas ya no aceptan pagos
  final Expense? expense;
  // Para decir quien debe confirmar
  final List<Member> members;
  final int? meId;
  // Se llama al cerrar el dialogo para que la pagina muestre el error
  final void Function(Debt debt) onNotify;
  final void Function(Debt debt) onConfirm;

  @override
  Widget build(BuildContext context) {
    final expense = this.expense;
    final status = paymentStatus(payment);
    final first = payment.debts.first;
    final text = Theme.of(context).textTheme;

    void act(void Function(Debt) action, Debt debt) {
      Navigator.of(context).pop();
      action(debt);
    }

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(payment.concept, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            Chip(
              label: Text(status.label),
              labelStyle: TextStyle(color: status.color.shade900, fontWeight: FontWeight.w600),
              backgroundColor: status.color.shade50,
              side: BorderSide(color: status.color),
            ),
            DetailRow(
              Icons.payments_outlined,
              'Total',
              formatMoney(sumAmounts(payment.debts.map((d) => d.amount)), first.currency),
            ),
            DetailRow(Icons.event_outlined, 'Periodo', formatDate(payment.period)),
            if (expense != null)
              DetailRow(Icons.repeat, 'Se repite', expense.frequency.label)
            else
              const DetailRow(Icons.delete_outline, 'Gasto', 'Eliminado'),
            Text('Pagos', style: text.titleSmall),
            for (final debt in payment.debts)
              _Share(
                debt,
                isMe: debt.debtorId == meId,
                others: expense?.participants.where((id) => id != debt.debtorId).length,
                waitingFor: [
                  for (final id in expense?.participants ?? const <int>[])
                    if (id != debt.debtorId && !debt.confirmers.contains(id))
                      members.where((m) => m.id == id).firstOrNull?.name ?? 'Ex miembro',
                ],
                // Solo el deudor dice que pago una vez y el backend rechaza a los demas
                onNotify: expense != null &&
                        debt.status == DebtStatus.pendiente &&
                        debt.debtorId == meId &&
                        debt.notifiedAt == null
                    ? () => act(onNotify, debt)
                    : null,
                // Otro participante que aun no confirma cuando el deudor ya dijo que pago
                onConfirm: expense != null &&
                        debt.status == DebtStatus.pendiente &&
                        debt.notifiedAt != null &&
                        debt.debtorId != meId &&
                        expense.participants.contains(meId) &&
                        !debt.confirmers.contains(meId)
                    ? () => act(onConfirm, debt)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Share extends StatelessWidget {
  const _Share(this.debt, {required this.isMe, required this.others, required this.waitingFor, this.onNotify, this.onConfirm});

  final Debt debt;
  final bool isMe;
  final int? others;
  // Nombres de quien falta por confirmar
  final List<String> waitingFor;
  final VoidCallback? onNotify;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final status = debtStatus(debt, others);
    final pending = debt.status == DebtStatus.pendiente;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MemberAvatar(debt.debtor),
      title: Text(isMe ? '${debt.debtor} (tú)' : debt.debtor),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: formatMoney(debt.amount, debt.currency)),
            TextSpan(
              text: ' · ${status.label}',
              style: TextStyle(color: status.color.shade800, fontWeight: FontWeight.w600),
            ),
            if (pending && debt.notifiedAt != null && waitingFor.isNotEmpty)
              TextSpan(text: '\nFalta: ${waitingFor.join(', ')}'),
          ],
        ),
      ),
      trailing: switch ((onNotify, onConfirm)) {
        (final notify?, _) => FilledButton.tonal(onPressed: notify, child: const Text('Ya pagué')),
        (_, final confirm?) => FilledButton.tonal(onPressed: confirm, child: const Text('Confirmar')),
        _ when debt.status == DebtStatus.aprobada => const Icon(Icons.check_circle, color: Colors.green),
        _ => null,
      },
    );
  }
}
