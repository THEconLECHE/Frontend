import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:flutter_roomiehub/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_roomiehub/features/chat/data/repositories/in_memory_chat_repository.dart';
import 'package:flutter_roomiehub/features/chat/domain/usecases/get_messages.dart';
import 'package:flutter_roomiehub/features/chat/domain/usecases/send_message.dart';
import 'package:flutter_roomiehub/features/chat/presentation/pages/chat_page.dart';

void main() {
  testWidgets('Sends a message, ignores blank ones and shows roommates by name', (tester) async {
    final auth = FakeAuthRepository();
    await auth.login('ana', 'x');
    final repo = InMemoryChatRepository();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatPage(
          houseId: 1,
          getMessages: GetMessages(repo),
          sendMessage: SendMessage(repo),
          getCurrentUser: GetCurrentUser(auth),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay mensajes. ¡Saluda a la casa!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(await repo.getMessages(1), isEmpty);

    await tester.enterText(find.byType(TextField), '  Hola casa  ');
    await tester.tap(find.byTooltip('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola casa'), findsOneWidget);
    // Los mensajes propios no repiten el nombre
    expect(find.text('ana'), findsNothing);

    // Un roomie escribe y aparece solo sin enviar nada
    await repo.sendMessage(1, 'Carlos', '¿Quién compra pan?');
    await repo.sendMessage(2, 'Carlos', 'De otra casa');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('¿Quién compra pan?'), findsOneWidget);
    expect(find.text('De otra casa'), findsNothing);
  });
}
