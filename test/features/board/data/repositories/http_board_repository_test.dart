import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/board/data/repositories/http_board_repository.dart';

void main() {
  test('notes come from the house: first line is the title, photos keep their thumbnail', () async {
    final sent = <String, Object?>{};
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        sent['${req.method} ${req.url.path}'] = req.body.isEmpty ? null : jsonDecode(req.body);
        return http.Response(
            jsonEncode(switch (req.url.path) {
              '/auth/login' => {'accessToken': 'jwt', 'refreshToken': 'r', 'usuario': {'id': 1, 'nombre': 'Ana'}},
              '/salas/7/notas' when req.method == 'GET' => {
                  'fijadas': [
                    {'id': 1, 'texto': 'Súper\nLeche\nPan', 'imagenMiniaturaUrl': null},
                  ],
                  'recientes': [
                    {'id': 2, 'texto': null, 'imagenMiniaturaUrl': 'http://img/2.jpg'},
                  ],
                },
              _ => {'id': 3},
            }),
            200,
            // El backend manda UTF 8 y sin charset el mock mandaria Latin 1
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    await auth.login('ana@mail.com', 'x');
    final repo = HttpBoardRepository(auth);

    final [note, photo] = await repo.getItems(7);
    expect((note.id, note.title, note.image), (1, 'Súper', null));
    expect(note.lines, ['Leche', 'Pan']);
    expect((photo.id, photo.title, photo.image), (2, '', 'http://img/2.jpg'));
    // Las fijadas llevan dos chinchetas en el tablon
    expect((note.pinned, photo.pinned), (true, false));

    await repo.addNote(7, 'Reunión', ['Sala 3', 'Sábado']);
    expect(sent['POST /salas/7/notas'], {'texto': 'Reunión\nSala 3\nSábado'});

    await repo.setPinned(2, true);
    final hasta = DateTime.parse((sent['PUT /notas/2/fijada'] as Map)['hasta'] as String);
    // Menos que el limite de 30 dias del backend
    expect(hasta.difference(DateTime.now()).inDays, 28);
    await repo.setPinned(2, false);
    expect(sent.keys, contains('DELETE /notas/2/fijada'));
  });
}
