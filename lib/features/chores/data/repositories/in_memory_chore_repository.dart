import '../../domain/entities/chore.dart';
import '../../domain/repositories/chore_repository.dart';

/* Para tests cada casa guarda sus tareas en memoria sin backend
   las tareas nuevas esperan a ser asignadas */
class InMemoryChoreRepository implements ChoreRepository {
  InMemoryChoreRepository([Map<int, List<Chore>> initial = const {}])
    : _chores = {
        for (final e in initial.entries) e.key: [...e.value],
      };

  final Map<int, List<Chore>> _chores;
  var _nextId = 1000;

  @override
  Future<List<Chore>> getChores(int houseId) async => List.unmodifiable(_chores[houseId] ?? const []);

  @override
  Future<void> addChore(int houseId, String title, String? description, ChoreFrequency frequency, int points) async =>
      (_chores[houseId] ??= []).add(
        Chore(
          id: _nextId++,
          title: title,
          assignee: null,
          queued: true,
          description: description,
          frequency: frequency,
          points: points,
        ),
      );

  @override
  Future<void> completeChore(int id) async {
    for (final chores in _chores.values) {
      final i = chores.indexWhere((c) => c.id == id);
      if (i != -1) chores[i] = Chore(id: id, title: chores[i].title, assignee: chores[i].assignee, done: true);
    }
  }

  // Cada tarea hecha vale sus puntos o 1 si no tiene
  @override
  Future<Map<String, int>> getPoints(int houseId) async {
    final points = <String, int>{};
    for (final c in _chores[houseId] ?? const <Chore>[]) {
      if (c.done && c.assignee != null) points[c.assignee!] = (points[c.assignee!] ?? 0) + (c.points ?? 1);
    }
    return points;
  }
}
