import 'package:flutter/material.dart';

import '../../domain/entities/chore.dart';

typedef NewChore = ({String title, String description, ChoreFrequency frequency, int points});

// Regresa la tarea nueva o null si se cancela
class NewChoreDialog extends StatefulWidget {
  const NewChoreDialog({super.key});

  @override
  State<NewChoreDialog> createState() => _NewChoreDialogState();
}

class _NewChoreDialogState extends State<NewChoreDialog> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _days = TextEditingController();
  // null cuando el usuario escribe los dias
  ChoreFrequency? _frequency = _presets[3];
  var _points = 3;

  static const _presets = [
    ChoreFrequency.everyDays(1),
    ChoreFrequency.everyDays(2),
    ChoreFrequency.everyDays(3),
    ChoreFrequency.everyDays(7),
    ChoreFrequency.monthly(),
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _days.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final frequency = _frequency ?? ChoreFrequency.everyDays(int.parse(_days.text));
    Navigator.of(
      context,
    ).pop<NewChore>((title: _title.text.trim(), description: _description.text, frequency: frequency, points: _points));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Cinco campos y el teclado no caben en un telefono pequeño
      scrollable: true,
      // Un poco mas ancho y fijo para que el texto largo baje de linea
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: const Text('Nueva tarea'),
      // Todo el ancho para que el dialogo no crezca al escribir
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              TextFormField(
                controller: _title,
                autofocus: true,
                maxLength: 80,
                minLines: 1,
                maxLines: 3,
                // Baja de linea como la descripcion pero Enter pasa al siguiente campo
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Tarea', hintText: 'Sacar la basura'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe la tarea' : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              DropdownButtonFormField<ChoreFrequency?>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Se repite'),
                items: [
                  for (final f in _presets) DropdownMenuItem(value: f, child: Text(f.label)),
                  const DropdownMenuItem(value: null, child: Text('Cada ... días')),
                ],
                onChanged: (v) => setState(() => _frequency = v),
              ),
              if (_frequency == null)
                TextFormField(
                  controller: _days,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cada cuántos días', suffixText: 'días'),
                  validator: (v) {
                    final days = int.tryParse(v?.trim() ?? '');
                    return days == null || days < 1 || days > ChoreFrequency.maxDays
                        ? 'Entre 1 y ${ChoreFrequency.maxDays}'
                        : null;
                  },
                ),
              // De 1 a 10 como en el backend y las tareas pesadas cuentan mas
              DropdownButtonFormField<int>(
                initialValue: _points,
                decoration: const InputDecoration(labelText: 'Puntos'),
                items: [for (var p = 1; p <= 10; p++) DropdownMenuItem(value: p, child: Text('$p'))],
                onChanged: (v) => _points = v ?? _points,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Agregar')),
      ],
    );
  }
}
