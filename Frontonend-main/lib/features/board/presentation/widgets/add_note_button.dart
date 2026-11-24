import 'dart:math';

import 'package:flutter/material.dart';

import '../board_style.dart';
import 'pinned.dart';

// Un post it pequeño que abre el formulario de nota nueva
class AddNoteButton extends StatelessWidget {
  const AddNoteButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Nueva nota',
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Transform.rotate(
            angle: 6 * pi / 180,
            child: SizedBox.square(
              dimension: 72,
              child: Pinned(
                pin: BoardStyle.pins.first,
                child: Container(
                  decoration: BoxDecoration(
                      color: BoardStyle.notes.first,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: BoardStyle.paperShadow),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 28, color: BoardStyle.ink),
                      Text('Nota', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BoardStyle.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
