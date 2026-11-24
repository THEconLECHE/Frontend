import 'package:flutter/material.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/board_item.dart';
import 'post_it.dart';

// Lo que el admin eligio y el tablon hace al cerrar la nota
enum NoteAction { pin, delete }

// La nota abierta como un post-it grande con like y dislike y las opciones del admin abajo
class NoteView extends StatefulWidget {
  const NoteView({
    super.key,
    required this.item,
    required this.color,
    required this.pin,
    required this.isAdmin,
    required this.onReact,
  });

  final BoardItem item;
  // Los mismos colores que tiene en el tablon
  final Color color;
  final Color pin;
  final bool isAdmin;
  // Lanza AuthException si el backend la rechaza
  final Future<void> Function(Reaction? reaction) onReact;

  @override
  State<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  late var _item = widget.item;
  var _busy = false;

  // Se ve al instante y vuelve atras si el backend falla
  Future<void> _react(Reaction tapped) async {
    if (_busy) return;
    final before = _item;
    // Tocar la misma otra vez la quita como en el backend
    final reaction = _item.myReaction == tapped ? null : tapped;
    setState(() {
      _item = _item.withReaction(reaction);
      _busy = true;
    });
    try {
      await widget.onReact(reaction);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _item = before);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final image = item.image;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 20,
        children: [
          PostIt(
            color: widget.color,
            pin: widget.pin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                if (item.title.isNotEmpty) Text(item.title, style: postItTitleStyle),
                Expanded(
                  child: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(image, fit: BoxFit.cover),
                        )
                      // Los renglones siguen al texto si es largo
                      : LayoutBuilder(
                          builder: (context, box) => SingleChildScrollView(
                            child: CustomPaint(
                              painter: const RuledLines(),
                              child: ConstrainedBox(
                                // Renglones en todo el papel aunque el texto sea corto
                                constraints: BoxConstraints(minHeight: box.maxHeight, minWidth: double.infinity),
                                child: Text(item.lines.join('\n'), style: postItBodyStyle),
                              ),
                            ),
                          ),
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    _Reaction(
                      icon: Icons.thumb_up,
                      label: 'Me gusta',
                      count: item.likes,
                      selected: item.myReaction == Reaction.like,
                      onTap: () => _react(Reaction.like),
                    ),
                    _Reaction(
                      icon: Icons.thumb_down,
                      label: 'No me gusta',
                      count: item.dislikes,
                      selected: item.myReaction == Reaction.dislike,
                      onTap: () => _react(Reaction.dislike),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.isAdmin)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, NoteAction.pin),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.push_pin_outlined),
                  label: Text(item.pinned ? 'Desfijar' : 'Fijar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, NoteAction.delete),
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Pulgar con su conteo que se pinta de azul si es la reaccion del usuario
class _Reaction extends StatelessWidget {
  const _Reaction({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : const Color(0x991F2937);
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            spacing: 4,
            children: [
              Icon(icon, size: 20, color: color),
              Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
