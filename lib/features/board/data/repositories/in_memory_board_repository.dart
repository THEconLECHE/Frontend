import '../../domain/entities/board_item.dart';
import '../../domain/repositories/board_repository.dart';

// Para tests cada casa guarda sus notas en memoria sin backend
class InMemoryBoardRepository implements BoardRepository {
  InMemoryBoardRepository([Map<int, List<BoardItem>> initial = const {}])
      : _items = {for (final e in initial.entries) e.key: [...e.value]};

  final Map<int, List<BoardItem>> _items;
  var _nextId = 1000;

  @override
  Future<List<BoardItem>> getItems(int houseId) async => List.unmodifiable(_items[houseId] ?? const []);

  @override
  Future<void> addNote(int houseId, String title, List<String> lines) async =>
      (_items[houseId] ??= []).insert(0, BoardItem.note(_nextId++, title, lines));

  /* shortcut se vuelve a crear como nota y una foto fijada pierde su imagen
     sirve mientras los tests solo fijen notas */
  @override
  Future<void> setPinned(int noteId, bool pinned) async {
    for (final items in _items.values) {
      final i = items.indexWhere((n) => n.id == noteId);
      if (i == -1) continue;
      final note = BoardItem.note(noteId, items[i].title, items[i].lines, pinned: pinned);
      items.removeAt(i);
      // Las fijadas van primero
      pinned ? items.insert(0, note) : items.add(note);
    }
  }

  @override
  Future<void> react(int noteId, Reaction? reaction) async {
    for (final items in _items.values) {
      final i = items.indexWhere((n) => n.id == noteId);
      if (i != -1) items[i] = items[i].withReaction(reaction);
    }
  }

  @override
  Future<void> deleteNote(int noteId) async {
    for (final items in _items.values) {
      items.removeWhere((n) => n.id == noteId);
    }
  }
}
