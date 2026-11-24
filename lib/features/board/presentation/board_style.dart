import 'package:flutter/material.dart';

abstract final class BoardStyle {
  static const pins = [Color(0xFFE53935), Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFFDD835), Color(0xFF8E24AA)];
  static const notes = [Color(0xFFFFF9C4), Color(0xFFFCE7F3), Color(0xFFDCFCE7), Color(0xFFDBEAFE), Color(0xFFF3E8FF), Color(0xFFFFEDD5)];
  static const ink = Color(0xFF1F2937);
  static const paperShadow = [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(1, 3))];
}
