// Una por persona y nota
enum Reaction { like, dislike }

// Una nota o foto pegada en el tablon de la casa sin imports de Flutter
class BoardItem {
  const BoardItem.note(this.id, this.title, this.lines,
      {this.pinned = false, this.likes = 0, this.dislikes = 0, this.myReaction})
      : image = null;
  const BoardItem.photo(this.id, this.title, this.image,
      {this.pinned = false, this.likes = 0, this.dislikes = 0, this.myReaction})
      : lines = const [];
  const BoardItem._(
      this.id, this.title, this.lines, this.image, this.pinned, this.likes, this.dislikes, this.myReaction);

  final int id;
  // El admin la fija arriba del tablon
  final bool pinned;
  final String title;
  final List<String> lines;
  // URL de la foto
  final String? image;
  final int likes;
  final int dislikes;
  // La del usuario actual o null si no ha reaccionado
  final Reaction? myReaction;

  // Cambia la reaccion del usuario actual y ajusta los conteos y null la quita
  BoardItem withReaction(Reaction? reaction) {
    int count(Reaction r, int n) => n - (myReaction == r ? 1 : 0) + (reaction == r ? 1 : 0);
    return BoardItem._(id, title, lines, image, pinned, count(Reaction.like, likes),
        count(Reaction.dislike, dislikes), reaction);
  }
}
