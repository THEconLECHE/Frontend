// Un turno de una tarea de la casa y el backend rota quien la hace
class Chore {
  const Chore({
    required this.id,
    required this.title,
    required this.assignee,
    this.done = false,
    this.queued = false,
    this.description,
    this.frequency,
    this.points,
    this.lastDay,
  });

  final int id;
  final String title;
  // null mientras nadie la tiene
  final String? assignee;
  final bool done;
  /* Recien creada y el backend le da su primer turno en la siguiente vuelta cada 15 minutos
     todavia no se puede completar */
  final bool queued;
  final String? description;
  final ChoreFrequency? frequency;
  final int? points;
  // Ultimo dia del turno en hora local y null mientras espera
  final DateTime? lastDay;
}

// Cada cierto numero de dias o cada mes si days es null
class ChoreFrequency {
  const ChoreFrequency.everyDays(int this.days) : assert(days >= 1 && days <= maxDays);
  const ChoreFrequency.monthly() : days = null;

  // El mismo limite que pone el backend
  static const maxDays = 365;

  final int? days;

  String get label => switch (days) {
    null => 'Mensual',
    1 => 'Diaria',
    7 => 'Semanal',
    final d => 'Cada $d días',
  };
}
