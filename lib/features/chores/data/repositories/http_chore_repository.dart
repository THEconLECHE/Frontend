import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/chore.dart';
import '../../domain/repositories/chore_repository.dart';

class HttpChoreRepository implements ChoreRepository {
  const HttpChoreRepository(this._auth);

  final AuthRepository _auth;

  // Los turnos actuales y las tareas que aun no tienen turno
  @override
  Future<List<Chore>> getChores(int houseId) async {
    final (turns, catalog) = await (
      _auth.request('GET', '/salas/$houseId/asignaciones'),
      _auth.request('GET', '/salas/$houseId/tareas'),
    ).wait;
    final assigned = (turns as List).cast<Map<String, dynamic>>();
    final withTurn = {for (final a in assigned) a['tareaId']};
    // El turno solo dice su tarea y los detalles vienen del catalogo
    final chores = {for (final t in (catalog as List).cast<Map<String, dynamic>>()) t['id']: t};
    return [
      for (final a in assigned)
        Chore(
          id: a['id'] as int,
          title: a['tarea'] as String,
          assignee: a['responsable'] as String?,
          done: a['estado'] == 'COMPLETADA',
          description: chores[a['tareaId']]?['descripcion'] as String?,
          frequency: _frequency(chores[a['tareaId']]?['frecuencia'] as String?),
          points: a['valor'] as int?,
          // El turno termina cuando empieza el siguiente y su ultimo dia es el anterior
          lastDay: DateTime.parse(a['periodoFin'] as String).toLocal().subtract(const Duration(seconds: 1)),
        ),
      for (final t in chores.values)
        if (!withTurn.contains(t['id']))
          // El id de la tarea porque aun no tiene turno que completar
          Chore(
            id: t['id'] as int,
            title: t['nombre'] as String,
            assignee: null,
            queued: true,
            description: t['descripcion'] as String?,
            frequency: _frequency(t['frecuencia'] as String?),
            points: t['valor'] as int?,
          ),
    ];
  }

  // Periodo ISO 8601 como P5D o P1M
  static ChoreFrequency? _frequency(String? iso) {
    if (iso == 'P1M') return const ChoreFrequency.monthly();
    final days = int.tryParse(RegExp(r'^P(\d+)D$').firstMatch(iso ?? '')?.group(1) ?? '');
    return days == null ? null : ChoreFrequency.everyDays(days);
  }

  @override
  Future<void> addChore(int houseId, String title, String? description, ChoreFrequency frequency, int points) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _auth.request(
      'POST',
      '/salas/$houseId/tareas',
      // Periodo ISO 8601 como P5D o P1M
      {
        'nombre': title,
        'descripcion': description,
        'valor': points,
        'frecuencia': frequency.days == null ? 'P1M' : 'P${frequency.days}D',
        'fechaInicio': today,
      },
    );
  }

  @override
  Future<void> completeChore(int id) => _auth.request('POST', '/asignaciones/$id/completar');

  // visible cuenta desde el inicio del trimestre y historico es todo y solo sirve para rotar
  @override
  Future<Map<String, int>> getPoints(int houseId) async => {
    for (final b in (await _auth.request('GET', '/salas/$houseId/balance') as List).cast<Map<String, dynamic>>())
      b['nombre'] as String: b['visible'] as int,
  };
}
