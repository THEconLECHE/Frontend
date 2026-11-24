import 'package:flutter/material.dart';

/* Se desliza en lugar de tocar para no confirmar por accidente
   los lectores de pantalla tambien pueden activarlo y cierra el dialogo al terminar */
class SlideToConfirm extends StatelessWidget {
  const SlideToConfirm(this.label, this.onConfirm, {super.key});

  final String label;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: 56,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(28)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
    return Semantics(
      button: true,
      onTap: () async {
        await onConfirm();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Stack(
        children: [
          bar,
          Dismissible(
            key: const ValueKey('slide-to-confirm'),
            direction: DismissDirection.startToEnd,
            // La pagina muestra el error cuando se cierra el dialogo
            confirmDismiss: (_) async {
              await onConfirm();
              return true;
            },
            onDismissed: (_) => Navigator.of(context).pop(),
            background: Container(
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(28)),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            child: Container(
              height: 56,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(4),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green,
                child: Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Una linea de etiqueta y valor en un dialogo de detalles
class DetailRow extends StatelessWidget {
  const DetailRow(this.icon, this.label, this.value, {super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Icon(icon, color: Colors.grey.shade700),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
