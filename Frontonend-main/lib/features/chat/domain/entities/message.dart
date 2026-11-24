class Message {
  const Message({required this.id, required this.author, required this.text, required this.sentAt});

  final int id;
  final String author;
  final String text;
  final DateTime sentAt;
}
