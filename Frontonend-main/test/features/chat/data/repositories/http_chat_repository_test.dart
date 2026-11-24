import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/chat/data/repositories/http_chat_repository.dart';

void main() {
  test('messages of the house come oldest first; sending posts the text', () async {
    final sent = <String, Object?>{};
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        sent['${req.method} ${req.url.path}'] = req.body.isEmpty ? null : jsonDecode(req.body);
        return http.Response(
            jsonEncode(switch (req.url.path) {
              '/auth/login' => {'accessToken': 'jwt', 'refreshToken': 'r', 'usuario': {'id': 1, 'nombre': 'Ana'}},
              '/salas/7/mensajes' when req.method == 'GET' => [
                  {'id': 2, 'autor': 'Carlos', 'texto': 'Yo voy', 'creadoEn': '2026-10-27T18:01:00Z'},
                  {'id': 1, 'autor': 'Ana', 'texto': '¿Quién compra pan?', 'creadoEn': '2026-10-27T18:00:00Z'},
                ],
              _ => {'id': 3},
            }),
            200,
            // El backend manda UTF 8 y sin charset el mock mandaria Latin 1
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    await auth.login('ana@mail.com', 'x');
    final repo = HttpChatRepository(auth);

    final messages = await repo.getMessages(7);
    expect([for (final m in messages) (m.id, m.author, m.text)], [(1, 'Ana', '¿Quién compra pan?'), (2, 'Carlos', 'Yo voy')]);
    expect(messages.first.sentAt, DateTime.utc(2026, 10, 27, 18).toLocal());

    await repo.sendMessage(7, 'Ana', 'Hola');
    expect(sent['POST /salas/7/mensajes'], {'texto': 'Hola'});
  });
}
