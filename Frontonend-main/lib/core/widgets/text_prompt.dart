import 'package:flutter/material.dart';

// Regresa el texto sin espacios o null si se cancela
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  required String empty,
  String initial = '',
  int? maxLength,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _TextPrompt(title, label, action, empty, initial, maxLength),
    );

class _TextPrompt extends StatefulWidget {
  const _TextPrompt(this.title, this.label, this.action, this.empty, this.initial, this.maxLength);

  final String title;
  final String label;
  final String action;
  final String empty;
  final String initial;
  final int? maxLength;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  final _form = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (_form.currentState!.validate()) Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _text,
          autofocus: true,
          maxLength: widget.maxLength,
          decoration: InputDecoration(labelText: widget.label),
          validator: (v) => v == null || v.trim().isEmpty ? widget.empty : null,
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: Text(widget.action)),
      ],
    );
  }
}
