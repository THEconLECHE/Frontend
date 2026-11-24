import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:flutter_roomiehub/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_roomiehub/features/chores/data/repositories/in_memory_chore_repository.dart';
import 'package:flutter_roomiehub/features/chores/domain/entities/chore.dart';
import 'package:flutter_roomiehub/features/chores/domain/usecases/add_chore.dart';
import 'package:flutter_roomiehub/features/chores/domain/usecases/complete_chore.dart';
import 'package:flutter_roomiehub/features/chores/domain/usecases/get_chores.dart';
import 'package:flutter_roomiehub/features/chores/domain/usecases/get_points.dart';
import 'package:flutter_roomiehub/features/chores/presentation/pages/chores_page.dart';

// Recuerda la frecuencia de la ultima tarea creada
class _Chores extends InMemoryChoreRepository {
  _Chores(super.initial);

  ChoreFrequency? lastFrequency;

  @override
  Future<void> addChore(int houseId, String title, String? description, ChoreFrequency frequency, int points) {
    lastFrequency = frequency;
    return super.addChore(houseId, title, description, frequency, points);
  }
}

void main() {
  Future<_Chores> pump(WidgetTester tester, {required bool isAdmin}) async {
    final repo = _Chores({
      1: const [
        Chore(id: 1, title: 'Sacar la basura', assignee: 'ana'),
        Chore(id: 2, title: 'Lavar platos', assignee: 'Carlos'),
      ],
      2: const [Chore(id: 3, title: 'Regar plantas', assignee: 'ana')],
    });
    final auth = FakeAuthRepository();
    await auth.register('ana', 'ana@mail.com', 'secreto');
    await tester.pumpWidget(
      MaterialApp(
        home: ChoresPage(
          houseId: 1,
          isAdmin: isAdmin,
          getChores: GetChores(repo),
          addChore: AddChore(repo),
          completeChore: CompleteChore(repo),
          getPoints: GetPoints(repo),
          getCurrentUser: GetCurrentUser(auth),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('Shows only this house\'s chores, completes one for good and filters mine', (tester) async {
    await pump(tester, isAdmin: false);
    expect(find.text('Sacar la basura'), findsOneWidget);
    expect(find.text('Regar plantas'), findsNothing);
    // Solo el admin crea tareas
    expect(find.text('Nueva tarea'), findsNothing);

    // Todos ven quien tiene cada tarea y si esta hecha
    expect(find.text('ana · Pendiente', findRichText: true), findsOneWidget);
    expect(find.text('Carlos · Pendiente', findRichText: true), findsOneWidget);
    // Mis puntos van en la esquina
    expect(find.text('0 pts'), findsOneWidget);

    // La tarea de Carlos no la puedo marcar yo
    await tester.tap(find.text('Lavar platos'));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para completar'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // La mia se marca deslizando desde sus detalles
    await tester.tap(find.text('Sacar la basura'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('ana · Completada', findRichText: true), findsOneWidget);
    expect(find.text('1 pts'), findsOneWidget);

    // Hecha no se puede deshacer
    await tester.tap(find.text('Sacar la basura'));
    await tester.pumpAndSettle();
    expect(find.text('Desliza para completar'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mis tareas'));
    await tester.pumpAndSettle();
    expect(find.text('Sacar la basura'), findsOneWidget);
    expect(find.text('Lavar platos'), findsNothing);
  });

  testWidgets('The admin adds a chore; it waits for the backend to assign it', (tester) async {
    final repo = await pump(tester, isAdmin: true);

    await tester.tap(find.text('Nueva tarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    expect(find.text('Escribe la tarea'), findsOneWidget);

    // Ancho fijo para que un nombre largo baje de linea
    final width = tester.getSize(find.byType(AlertDialog)).width;
    await tester.enterText(find.byType(TextFormField).at(0), 'Trapear ' * 9);
    await tester.pump();
    expect(tester.getSize(find.byType(AlertDialog)).width, width);

    await tester.enterText(find.byType(TextFormField).at(0), 'Trapear');
    await tester.enterText(find.byType(TextFormField).at(1), 'Con el trapeador azul');
    // Cualquier numero de dias y no solo los de la lista
    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cada ... días').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '400');
    await tester.tap(find.text('Agregar'));
    await tester.pump();
    expect(find.text('Entre 1 y 365'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(repo.lastFrequency?.days, 5);
    // Aparece de inmediato esperando su primer turno y nadie la puede marcar
    expect(find.text('Trapear'), findsOneWidget);
    expect(find.text('Sin asignar · Por asignar', findRichText: true), findsOneWidget);

    // Al tocarla se abren sus detalles con la descripcion
    await tester.tap(find.text('Trapear'));
    await tester.pumpAndSettle();
    expect(find.text('Con el trapeador azul'), findsOneWidget);
    expect(find.text('Cada 5 días'), findsOneWidget);
    expect(find.text('Por asignar'), findsOneWidget);
    expect(find.text('Desliza para completar'), findsNothing);
  });
}
