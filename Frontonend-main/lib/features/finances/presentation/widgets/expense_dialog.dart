import 'package:flutter/material.dart';

import '../../../house/domain/entities/house.dart';
import '../../domain/entities/expense.dart';

String formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

String formatMoney(String amount, Currency currency) => '\$$amount ${currency.name.toUpperCase()}';

// Regresa el gasto lleno o null si se cancela y con initial edita ese gasto
class ExpenseDialog extends StatefulWidget {
  const ExpenseDialog({super.key, required this.members, this.initial});

  final List<Member> members;
  final Expense? initial;

  @override
  State<ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  final _form = GlobalKey<FormState>();
  late final _concept = TextEditingController(text: widget.initial?.concept);
  late final _amount = TextEditingController(text: widget.initial?.amount);
  late var _currency = widget.initial?.currency ?? Currency.mxn;
  late var _frequency = widget.initial?.frequency ?? ExpenseFrequency.mensual;
  late var _startDate = widget.initial?.startDate ?? DateUtils.dateOnly(DateTime.now());
  // Todos por defecto porque casi todo se reparte entre la casa
  late var _participants = {...(widget.initial?.participants ?? widget.members.map((m) => m.id))};

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _concept.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      // El backend rechaza fechas de mas de un año porque crearia un año de deudas
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop<ExpenseDraft>((
      concept: _concept.text,
      amount: _amount.text.trim().replaceAll(',', '.'),
      currency: _currency,
      frequency: _frequency,
      startDate: _startDate,
      // En el orden de los miembros porque asi reparte el backend los centavos
      participants: [for (final m in widget.members) if (_participants.contains(m.id)) m.id],
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Un gasto unico no puede volverse recurrente ni al reves
    final frequencies = _editing
        ? ExpenseFrequency.values.where((f) => (f == ExpenseFrequency.unica) == (_frequency == ExpenseFrequency.unica))
        : ExpenseFrequency.values;

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(_editing ? 'Editar gasto' : 'Nuevo gasto'),
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
                controller: _concept,
                autofocus: !_editing,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Concepto', hintText: 'Renta'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el concepto' : null,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto total', prefixText: '\$'),
                      validator: (v) {
                        final text = v?.trim().replaceAll(',', '.') ?? '';
                        // Hasta el limite NUMERIC del backend y mayor que cero
                        if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) return 'Monto con hasta 2 decimales';
                        return double.parse(text) == 0 ? 'Mayor que cero' : null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<Currency>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: [
                        for (final c in Currency.values) DropdownMenuItem(value: c, child: Text(c.name.toUpperCase())),
                      ],
                      // Las deudas ya creadas la usan
                      onChanged: _editing ? null : (v) => _currency = v ?? _currency,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<ExpenseFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Se repite'),
                items: [for (final f in frequencies) DropdownMenuItem(value: f, child: Text(f.label))],
                onChanged: frequencies.length == 1 ? null : (v) => setState(() => _frequency = v ?? _frequency),
              ),
              if (!_editing)
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Desde', suffixIcon: Icon(Icons.event_outlined)),
                    child: Text(formatDate(_startDate)),
                  ),
                ),
              FormField<Set<int>>(
                validator: (_) => _participants.isEmpty ? 'Elige al menos a uno' : null,
                builder: (field) => InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Se divide entre',
                    border: InputBorder.none,
                    errorText: field.errorText,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final m in widget.members)
                        FilterChip(
                          label: Text(m.name),
                          selected: _participants.contains(m.id),
                          onSelected: (on) => setState(
                            () => _participants = on ? {..._participants, m.id} : ({..._participants}..remove(m.id)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: Text(_editing ? 'Guardar' : 'Agregar')),
      ],
    );
  }
}
