import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/board_item.dart';
import '../../domain/repositories/board_repository.dart';

// El backend guarda la nota como texto y la primera linea es el titulo
class HttpBoardRepository implements BoardRepository {
  const HttpBoardRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<List<BoardItem>> getItems(int houseId) async {
    /* shortcut solo trae las primeras 50 notas
       agregar paginas con antesDe cuando crezcan los tableros */
    final board = await _auth.request('GET', '/salas/$houseId/notas') as Map<String, dynamic>;
    return [
      for (final n in (board['fijadas'] as List).cast<Map<String, dynamic>>()) _item(n, pinned: true),
      for (final n in (board['recientes'] as List).cast<Map<String, dynamic>>()) _item(n, pinned: false),
    ];
  }

  static BoardItem _item(Map<String, dynamic> n, {required bool pinned}) {
    final id = n['id'] as int;
    final lines = ((n['texto'] as String?) ?? '').split('\n');
    final photo = n['imagenMiniaturaUrl'] as String?;
    final likes = (n['likes'] as int?) ?? 0;
    final dislikes = (n['dislikes'] as int?) ?? 0;
    final reaction = switch (n['miReaccion']) { 'LIKE' => Reaction.like, 'DISLIKE' => Reaction.dislike, _ => null };
    return photo != null
        ? BoardItem.photo(id, lines.first, photo,
            pinned: pinned, likes: likes, dislikes: dislikes, myReaction: reaction)
        : BoardItem.note(id, lines.first, lines.sublist(1),
            pinned: pinned, likes: likes, dislikes: dislikes, myReaction: reaction);
  }

  @override
  Future<void> addNote(int houseId, String title, List<String> lines) =>
      _auth.request('POST', '/salas/$houseId/notas', {'texto': [title, ...lines].join('\n')});

  // El backend permite hasta 30 dias y se usan 29 por si el reloj del telefono va adelantado
  @override
  Future<void> setPinned(int noteId, bool pinned) => pinned
      ? _auth.request('PUT', '/notas/$noteId/fijada', {
          'hasta': DateTime.now().toUtc().add(const Duration(days: 29)).toIso8601String(),
        })
      : _auth.request('DELETE', '/notas/$noteId/fijada');

  @override
  Future<void> react(int noteId, Reaction? reaction) => reaction == null
      ? _auth.request('DELETE', '/notas/$noteId/reaccion')
      : _auth.request('PUT', '/notas/$noteId/reaccion', {'tipo': reaction.name.toUpperCase()});

  @override
  Future<void> deleteNote(int noteId) => _auth.request('DELETE', '/notas/$noteId');
}
