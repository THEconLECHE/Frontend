// Un gasto compartido y cada periodo el backend lo reparte en deudas
class Expense {
  const Expense({
    required this.id,
    required this.concept,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.startDate,
    required this.participants,
  });

  final int id;
  final String concept;
  // Texto decimal como lo manda el backend porque un double pierde centavos
  final String amount;
  final Currency currency;
  final ExpenseFrequency frequency;
  final DateTime startDate;
  // Ids de miembros en el orden del backend que reparte los centavos sobrantes
  final List<int> participants;
}

/* Lo que llena el admin para crear o editar un gasto
   al editar se quedan la moneda y la fecha de inicio */
typedef ExpenseDraft = ({
  String concept,
  String amount,
  Currency currency,
  ExpenseFrequency frequency,
  DateTime startDate,
  List<int> participants,
});

// Un gasto por moneda sin convertir
enum Currency { mxn, usd }

// Un gasto unico crea sus deudas una vez en su fecha de inicio
enum ExpenseFrequency {
  unica('Único'),
  semanal('Semanal'),
  mensual('Mensual'),
  bimestral('Bimestral');

  const ExpenseFrequency(this.label);

  final String label;
}

// La parte de un miembro en un gasto por un periodo
class Debt {
  const Debt({
    required this.id,
    required this.expenseId,
    required this.concept,
    required this.period,
    required this.debtorId,
    required this.debtor,
    required this.amount,
    required this.currency,
    required this.status,
    this.notifiedAt,
    this.confirmers = const {},
  });

  final int id;
  final int expenseId;
  final String concept;
  // Primer dia del periodo que cobra
  final DateTime period;
  final int debtorId;
  final String debtor;
  final String amount;
  final Currency currency;
  final DebtStatus status;
  // Cuando el deudor dijo que pago y null antes
  final DateTime? notifiedAt;
  // Quien ya confirmo que recibio el pago y se paga cuando todos los demas confirman
  final Set<int> confirmers;
}

/* Repartida cuando el deudor se fue y su parte paso a los demas
   pagada y repartida ya no cambian */
enum DebtStatus { pendiente, aprobada, repartida }
