import '../entities/board_item.dart';

abstract interface class BoardRepository {
  /* Primero las fijadas y luego de la mas nueva a la mas vieja
     lanza AuthException con un mensaje para el usuario */
  Future<List<BoardItem>> getItems(int houseId);

  Future<void> addNote(int houseId, String title, List<String> lines);

  // Solo el admin y maximo 3 fijadas a la vez
  Future<void> setPinned(int noteId, bool pinned);

  // null quita la reaccion del usuario actual
  Future<void> react(int noteId, Reaction? reaction);

  // Solo el admin
  Future<void> deleteNote(int noteId);
}
