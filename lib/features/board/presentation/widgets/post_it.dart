import 'package:flutter/material.dart';

import '../board_style.dart';
import 'pinned.dart';

// Alto de cada renglon del papel y del texto escrito encima
const postItLineHeight = 28.0;
const postItBodyStyle = TextStyle(fontSize: 16, height: postItLineHeight / 16, color: Color(0xFF4B5563));
const postItTitleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: BoardStyle.ink);

// Un post-it grande con chincheta para escribir o leer una nota
class PostIt extends StatelessWidget {
  const PostIt({super.key, required this.color, required this.pin, required this.child});

  final Color color;
  final Color pin;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 300,
        child: Pinned(
          pin: pin,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4), boxShadow: BoardStyle.paperShadow),
            child: child,
          ),
        ),
      );
}

// Renglones del papel alineados con cada linea del contenido
class RuledLines extends CustomPainter {
  const RuledLines();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x331F2937)
      ..strokeWidth = 1;
    for (var y = postItLineHeight; y <= size.height; y += postItLineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(RuledLines old) => false;
}
