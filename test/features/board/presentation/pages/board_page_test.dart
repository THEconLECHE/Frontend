import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/features/board/data/repositories/in_memory_board_repository.dart';
import 'package:flutter_roomiehub/features/board/domain/entities/board_item.dart';
import 'package:flutter_roomiehub/features/board/domain/usecases/add_note.dart';
import 'package:flutter_roomiehub/features/board/domain/usecases/delete_note.dart';
import 'package:flutter_roomiehub/features/board/domain/usecases/get_notes.dart';
import 'package:flutter_roomiehub/features/board/domain/usecases/pin_note.dart';
import 'package:flutter_roomiehub/features/board/domain/usecases/react_to_note.dart';
import 'package:flutter_roomiehub/features/board/presentation/pages/board_page.dart';
import 'package:flutter_roomiehub/features/board/presentation/widgets/pinned.dart';

Widget _board(InMemoryBoardRepository repo, {bool isAdmin = false}) => MaterialApp(
  home: Scaffold(
    body: BoardPage(
      houseId: 1,
      isAdmin: isAdmin,
      getNotes: GetNotes(repo),
      addNote: AddNote(repo),
      pinNote: PinNote(repo),
      reactToNote: ReactToNote(repo),
      deleteNote: DeleteNote(repo),
    ),
  ),
);

void main() {
  testWidgets('Shows this house\'s notes instead of the empty message', (tester) async {
    await tester.pumpWidget(_board(InMemoryBoardRepository({
      1: const [BoardItem.note(1, 'Reunión', ['Sala 3'])],
      2: const [BoardItem.note(2, 'De otra casa', [])],
    })));
    await tester.pumpAndSettle();

    expect(find.text('Reunión'), findsOneWidget);
    expect(find.text('Sala 3'), findsOneWidget);
    expect(find.text('De otra casa'), findsNothing);
    expect(find.text('Aún no hay notas'), findsNothing);
  });

  testWidgets('Post-it button adds a note; empty title is rejected', (tester) async {
    await tester.pumpWidget(_board(InMemoryBoardRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay notas'), findsOneWidget);

    await tester.tap(find.byTooltip('Nueva nota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    expect(find.text('Ponle un título'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Súper');
    // Mas lineas de las que caben deben cortarse sin desbordar
    await tester.enterText(find.byType(TextFormField).at(1), 'Leche\nPan\nHuevos\nCafé\nArroz\nFrutas');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();

    expect(find.text('Súper'), findsOneWidget);
    expect(find.text('Aún no hay notas'), findsNothing);
  });

  testWidgets('Only the admin pins a note: long press, and it gets two thumbtacks', (tester) async {
    Pinned pinned() => tester.widget<Pinned>(find.ancestor(of: find.text('Reunión'), matching: find.byType(Pinned)));
    final repo = InMemoryBoardRepository({
      1: const [BoardItem.note(1, 'Reunión', ['Sala 3'])],
    });

    await tester.pumpWidget(_board(repo));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Reunión'));
    await tester.pumpAndSettle();
    expect(find.text('Fijar nota'), findsNothing);
    // Al soltar cuenta como toque y abre la hoja de la nota asi que se cierra
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_board(repo, isAdmin: true));
    await tester.pumpAndSettle();
    expect(pinned().tacks, 1);
    await tester.longPress(find.text('Reunión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fijar'));
    await tester.pumpAndSettle();
    expect(pinned().tacks, 2);

    await tester.longPress(find.text('Reunión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desfijar'));
    await tester.pumpAndSettle();
    expect(pinned().tacks, 1);
  });

  testWidgets('Tapping a note reacts: like, switch to dislike, tap again removes it', (tester) async {
    final repo = InMemoryBoardRepository({
      1: const [BoardItem.note(1, 'Reunión', ['Sala 3'], likes: 2)],
    });
    await tester.pumpWidget(_board(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reunión'));
    await tester.pumpAndSettle();
    // Un miembro no ve opciones de admin
    expect(find.text('Eliminar'), findsNothing);

    Future<(int, int)> counts() async => switch (await repo.getItems(1)) { [final n] => (n.likes, n.dislikes), _ => (-1, -1) };
    await tester.tap(find.byTooltip('Me gusta'));
    await tester.pumpAndSettle();
    expect(await counts(), (3, 0));
    await tester.tap(find.byTooltip('No me gusta'));
    await tester.pumpAndSettle();
    expect(await counts(), (2, 1));
    await tester.tap(find.byTooltip('No me gusta'));
    await tester.pumpAndSettle();
    expect(await counts(), (2, 0));
  });

  testWidgets('Only the admin deletes a note after confirming', (tester) async {
    final repo = InMemoryBoardRepository({
      1: const [BoardItem.note(1, 'Reunión', ['Sala 3'])],
    });
    await tester.pumpWidget(_board(repo, isAdmin: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reunión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Reunión'), findsNothing);
    expect(find.text('Aún no hay notas'), findsOneWidget);
  });
}
