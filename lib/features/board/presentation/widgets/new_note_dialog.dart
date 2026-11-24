import 'dart:math';

import 'package:flutter/material.dart';

import '../board_style.dart';
import 'post_it.dart';

typedef NewNote = ({String title, List<String> lines});

// Regresa la nota nueva o null si se cancela
class NewNoteDialog extends StatefulWidget {
  const NewNoteDialog({super.key});

  @override
  State<NewNoteDialog> createState() => _NewNoteDialogState();
}

class _NewNoteDialogState extends State<NewNoteDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  // Cada nota nueva sale de un color de post-it distinto
  final _color = BoardStyle.notes[Random().nextInt(BoardStyle.notes.length)];
  final _pin = BoardStyle.pins[Random().nextInt(BoardStyle.pins.length)];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final lines = [
      for (final l in _body.text.split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];
    Navigator.of(context).pop<NewNote>((title: _title.text.trim(), lines: lines));
  }

  @override
  Widget build(BuildContext context) {
    // Sin bordes ni etiquetas para que se escriba directo sobre el papel
    InputDecoration paper(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x661F2937)),
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      counterText: '',
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            PostIt(
              color: _color,
              pin: _pin,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  TextFormField(
                    controller: _title,
                    autofocus: true,
                    maxLength: 30,
                    style: postItTitleStyle,
                    decoration: paper('Título'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: const RuledLines(),
                      child: TextFormField(
                        controller: _body,
                        expands: true,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        style: postItBodyStyle,
                        decoration: paper('Una idea por línea'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Cancelar'),
                ),
                FilledButton(onPressed: _save, child: const Text('Agregar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
