import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/member_avatar.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/get_messages.dart';
import '../../domain/usecases/send_message.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.houseId,
    required this.getMessages,
    required this.sendMessage,
    required this.getCurrentUser,
  });

  final int houseId;
  final GetMessages getMessages;
  final SendMessage sendMessage;
  final GetCurrentUser getCurrentUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  // null mientras carga la primera vez
  List<Message>? _messages;
  /* shortcut pregunta al backend cada pocos segundos
     cambiar a STOMP cuando muchas casas usen el chat */
  late final Timer _poll;

  String get _me => widget.getCurrentUser() ?? 'Yo';

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll.cancel();
    _input.dispose();
    super.dispose();
  }

  // Si falla una recarga en segundo plano no muestra nada para no juntar errores
  Future<void> _load({bool quiet = false}) async {
    try {
      final messages = await widget.getMessages(widget.houseId);
      if (mounted) setState(() => _messages = messages);
    } on AuthException catch (e) {
      if (!quiet) _show(e.message);
    }
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    try {
      await widget.sendMessage(widget.houseId, _me, text);
    } on AuthException catch (e) {
      // Regresa el texto para que no se pierda
      _input.text = text;
      return _show(e.message);
    }
    await _load();
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;
    return Column(
      children: [
        Expanded(
          child: messages != null && messages.isEmpty
              ? const Center(child: Text('Aún no hay mensajes. ¡Saluda a la casa!'))
              : ListView.builder(
                  // Invertida para empezar en el mensaje mas nuevo pegado abajo
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  itemCount: messages?.length ?? 0,
                  itemBuilder: (_, i) {
                    final index = messages!.length - 1 - i;
                    final previous = index > 0 ? messages[index - 1] : null;
                    return _Bubble(
                      message: messages[index],
                      mine: messages[index].author == _me,
                      // Nombre y avatar solo en el primer mensaje seguido de la misma persona
                      showAuthor: previous?.author != messages[index].author,
                    );
                  },
                ),
        ),
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: SendMessage.maxLength,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  tooltip: 'Enviar',
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, required this.showAuthor});

  final Message message;
  final bool mine;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt));
    final foreground = mine ? colors.onPrimary : colors.onSurface;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: mine ? colors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine && showAuthor)
            Text(message.author, style: TextStyle(fontWeight: FontWeight.w600, color: colors.primary)),
          Text(message.text, style: TextStyle(color: foreground, fontSize: 15)),
          Align(
            alignment: Alignment.bottomRight,
            widthFactor: 1,
            child: Text(time, style: TextStyle(color: foreground.withValues(alpha: 0.7), fontSize: 11)),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: showAuthor ? 10 : 2),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            // Espacio vacio para alinear los mensajes bajo el avatar
            showAuthor ? MemberAvatar(message.author, radius: 16) : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          bubble,
        ],
      ),
    );
  }
}
