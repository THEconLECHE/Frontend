import 'dart:math';

import 'package:flutter/material.dart';

// Fondo de corcho con marco de madera
class CorkBoard extends StatelessWidget {
  const CorkBoard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFC9A27B),
        border: Border.all(color: const Color(0xFF8B5E3C), width: 10),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: CustomPaint(painter: _CorkTexture(), child: child),
    );
  }
}

// Puntos claros y oscuros para que parezca corcho con semilla fija para que no cambien
class _CorkTexture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final paint = Paint();
    for (var i = 0; i < size.width * size.height / 90; i++) {
      paint.color = rnd.nextBool() ? const Color(0x40704A2A) : const Color(0x50F1D9B5);
      canvas.drawCircle(
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), rnd.nextDouble() * 1.5 + 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_CorkTexture oldDelegate) => false;
}
