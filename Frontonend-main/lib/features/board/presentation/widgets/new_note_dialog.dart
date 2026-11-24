import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final lines = [for (final l in _body.text.split('\n')) if (l.trim().isNotEmpty) l.trim()];
    Navigator.of(context).pop<NewNote>((title: _title.text.trim(), lines: lines));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva nota'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ponle un título' : null,
            ),
            TextFormField(
              controller: _body,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Contenido', hintText: 'Una idea por línea'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Agregar')),
      ],
    );
  }
}
