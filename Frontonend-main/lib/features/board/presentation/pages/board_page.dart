import 'dart:math';

import 'package:flutter/material.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/board_item.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/pin_note.dart';
import '../board_style.dart';
import '../widgets/add_note_button.dart';
import '../widgets/board_card.dart';
import '../widgets/cork_board.dart';
import '../widgets/new_note_dialog.dart';
import '../widgets/pinned.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({
    super.key,
    required this.houseId,
    required this.isAdmin,
    required this.getNotes,
    required this.addNote,
    required this.pinNote,
  });

  final int houseId;
  // Solo el admin fija notas
  final bool isAdmin;
  final GetNotes getNotes;
  final AddNote addNote;
  final PinNote pinNote;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  // null mientras carga la primera vez
  List<BoardItem>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.getNotes(widget.houseId);
      if (mounted) setState(() => _items = items);
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addNote() async {
    final note = await showDialog<NewNote>(context: context, builder: (_) => const NewNoteDialog());
    if (note == null) return;
    try {
      await widget.addNote(widget.houseId, note.title, note.lines);
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    await _load();
  }

  Future<void> _togglePin(BoardItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.pinned ? 'Desfijar nota' : 'Fijar nota'),
        content: Text(item.pinned ? 'Deja de estar arriba del tablón.' : 'Se queda arriba del tablón por 29 días.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(item.pinned ? 'Desfijar' : 'Fijar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.pinNote(item.id, !item.pinned);
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tablón de Notas', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: CorkBoard(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: switch (items) {
                      null => const SizedBox.shrink(),
                      [] => const Center(
                          child: Text('Aún no hay notas',
                              style: TextStyle(color: Color(0xFF5D3F25), fontSize: 16, fontWeight: FontWeight.w500)),
                        ),
                      _ => GridView.count(
                          // Espacio extra abajo para que el boton no tape la ultima fila
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                          crossAxisCount: 3,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 14,
                          children: [
                            for (final (i, item) in items.indexed)
                              // El color y la inclinacion salen del id para que la nota se vea igual en todos los telefonos
                              Transform.rotate(
                                angle: (item.id * 7 % 9 - 4) * pi / 180,
                                // El admin mantiene presionada una nota para fijarla o quitarla
                                child: GestureDetector(
                                  onLongPress: widget.isAdmin ? () => _togglePin(item) : null,
                                  child: Pinned(
                                    pin: BoardStyle.pins[i % BoardStyle.pins.length],
                                    tacks: item.pinned ? 2 : 1,
                                    child: BoardCard(item, color: BoardStyle.notes[item.id % BoardStyle.notes.length]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    },
                  ),
                  Positioned(right: 18, bottom: 18, child: AddNoteButton(onTap: _addNote)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
