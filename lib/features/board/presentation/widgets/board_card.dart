import 'package:flutter/material.dart';

import '../../domain/entities/board_item.dart';
import '../board_style.dart';

class BoardCard extends StatelessWidget {
  const BoardCard(this.item, {super.key, required this.color});

  final BoardItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final image = item.image;
    if (image != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(4),
          boxShadow: BoardStyle.paperShadow,
          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(4)),
          child: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4), boxShadow: BoardStyle.paperShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 14 / 12, color: BoardStyle.ink)),
          // Un bloque de texto que se desvanece si no cabe en la nota
          Expanded(
            child: Text(item.lines.join('\n'),
                overflow: TextOverflow.fade,
                style: const TextStyle(fontSize: 10, height: 1.8, color: Color(0xFF4B5563))),
          ),
        ],
      ),
    );
  }
}
