// Una nota o foto pegada en el tablon de la casa sin imports de Flutter
class BoardItem {
  const BoardItem.note(this.id, this.title, this.lines, {this.pinned = false}) : image = null;
  const BoardItem.photo(this.id, this.title, this.image, {this.pinned = false}) : lines = const [];

  final int id;
  // El admin la fija arriba del tablon
  final bool pinned;
  final String title;
  final List<String> lines;
  // URL de la foto
  final String? image;
}
