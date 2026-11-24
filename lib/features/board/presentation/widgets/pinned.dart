import 'package:flutter/material.dart';

// Pone chinchetas de color encima del hijo una en medio o dos en las esquinas
class Pinned extends StatelessWidget {
  const Pinned({super.key, required this.pin, required this.child, this.tacks = 1}) : assert(tacks == 1 || tacks == 2);

  final Color pin;
  final Widget child;
  final int tacks;

  @override
  Widget build(BuildContext context) {
    // Cabeza de chincheta vista desde arriba con brillo y sombra
    final tack = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.4, -0.4), colors: [Color.lerp(pin, Colors.white, 0.6)!, pin]),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(1, 2))],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: -6,
          left: 10,
          right: 10,
          child: Row(
            mainAxisAlignment: tacks == 1 ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [for (var i = 0; i < tacks; i++) tack],
          ),
        ),
      ],
    );
  }
}
