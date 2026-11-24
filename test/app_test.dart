import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/app.dart';
import 'package:flutter_roomiehub/features/auth/data/repositories/fake_auth_repository.dart';

void main() {
  testWidgets('Splash -> login -> room menu', (tester) async {
    await tester.pumpWidget(RoomieHubApp(auth: FakeAuthRepository()));
    expect(find.text('RoomieHub'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Con campos vacios no se puede entrar
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Campo obligatorio'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@mail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opciones de sala'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir sala'), findsOneWidget);
    expect(find.text('Dejar sala'), findsOneWidget);
    // Sin casa nadie es admin porque el falso no tiene backend
    expect(find.text('Administrar sala'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    // Sin backend la casa no carga y sale el error sin contenido
    expect(find.text('Sin servidor en las pruebas'), findsOneWidget);
    expect(find.text('Tablón de Notas'), findsNothing);
  });
}
