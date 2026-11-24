import 'package:flutter/material.dart';

import '../../../../core/widgets/member_avatar.dart';
import '../../../../core/widgets/slide_to_confirm.dart';
import '../../domain/entities/chore.dart';

// Amarillo espera verde hecha rojo pendiente
({MaterialColor color, String label}) choreStatus(Chore chore) => chore.queued
    ? (color: Colors.amber, label: 'Por asignar')
    : chore.done
    ? (color: Colors.green, label: 'Completada')
    : (color: Colors.red, label: 'Pendiente');

// Todos los datos de una tarea al tocarla en la lista
class ChoreDetailsDialog extends StatelessWidget {
  const ChoreDetailsDialog(this.chore, {super.key, this.onComplete});

  final Chore chore;
  // null si este usuario no puede marcarla y oculta el deslizador
  final Future<void> Function()? onComplete;

  @override
  Widget build(BuildContext context) {
    final status = choreStatus(chore);
    final description = chore.description;
    final frequency = chore.frequency;
    final points = chore.points;
    final lastDay = chore.lastDay;
    final text = Theme.of(context).textTheme;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(chore.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            Chip(
              label: Text(status.label),
              labelStyle: TextStyle(color: status.color.shade900, fontWeight: FontWeight.w600),
              backgroundColor: status.color.shade50,
              side: BorderSide(color: status.color),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: MemberAvatar(chore.assignee ?? '?'),
              title: Text(chore.assignee ?? 'Sin asignar'),
              subtitle: const Text('Responsable'),
            ),
            if (frequency != null) DetailRow(Icons.repeat, 'Se repite', frequency.label),
            if (points != null) DetailRow(Icons.star_outline, 'Puntos', '$points'),
            if (lastDay != null && !chore.done)
              DetailRow(Icons.event_outlined, 'Hasta', '${lastDay.day}/${lastDay.month}/${lastDay.year}'),
            Text('Descripción', style: text.titleSmall),
            Text(
              description ?? 'Sin descripción',
              style: description == null ? text.bodyMedium?.copyWith(color: Colors.grey) : text.bodyMedium,
            ),
            if (onComplete case final complete?) ...[
              const SizedBox(height: 12),
              SlideToConfirm('Desliza para completar', complete),
            ],
          ],
        ),
      ),
    );
  }
}
