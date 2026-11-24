import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/house/data/repositories/http_house_repository.dart';

void main() {
  final responses = <String, Object?>{
    '/auth/login': {
      'accessToken': 'jwt',
      'refreshToken': 'refresh-1',
      'usuario': {'id': 1, 'nombre': 'Ana', 'email': 'ana@mail.com', 'fotoUrl': null},
    },
    // La lista no trae miembros y el detalle si
    '/salas': [
      {'id': 7, 'nombre': 'Casa 304', 'codigoInvitacion': 'R9NUQGBV', 'miRol': 'ADMIN', 'miembros': []},
    ],
    '/salas/7': {
      'id': 7,
      'nombre': 'Casa 304',
      'codigoInvitacion': 'R9NUQGBV',
      'miRol': 'ADMIN',
      'miembros': [
        {'usuarioId': 2, 'nombre': 'Carlos', 'rol': 'HABITANTE'},
        {'usuarioId': 1, 'nombre': 'Ana', 'rol': 'ADMIN'},
      ],
    },
  };

  Future<HttpHouseRepository> loggedIn(Map<String, Object?> sent) async {
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        sent['${req.method} ${req.url.path}'] = req.body.isEmpty ? null : jsonDecode(req.body);
        final body = responses[req.url.path];
        return body == null ? http.Response('', 204) : http.Response(jsonEncode(body), 200);
      }),
    );
    await auth.login('ana@mail.com', 'secreta123');
    return HttpHouseRepository(auth);
  }

  test('current house comes with its members and the user\'s role', () async {
    final repo = await loggedIn({});

    final house = (await repo.getCurrentHouse())!;
    expect(house.name, 'Casa 304');
    expect(house.inviteCode, 'R9NUQGBV');
    expect(house.isAdmin, isTrue);
    expect([for (final m in house.members) (m.id, m.name, m.isAdmin)], [(2, 'Carlos', false), (1, 'Ana', true)]);
  });

  test('admin actions hit their endpoints', () async {
    final sent = <String, Object?>{};
    final repo = await loggedIn(sent);

    await repo.transferAdmin(7, 2);
    await repo.expel(7, 2);
    await repo.deactivate(7);
    await repo.leave(7);

    expect(sent['POST /salas/7/administrador'], {'usuarioId': 2});
    expect(sent.keys, containsAll(['DELETE /salas/7/miembros/2', 'POST /salas/7/desactivar', 'DELETE /salas/7/membresia']));
  });

  test('joining selects the new house; a house the user left falls back to the first', () async {
    responses['/salas'] = [
      {'id': 7, 'nombre': 'Casa 304', 'miRol': 'ADMIN'},
      {'id': 8, 'nombre': 'Depa', 'miRol': 'HABITANTE'},
    ];
    responses['/salas/8'] = {'id': 8, 'nombre': 'Depa', 'codigoInvitacion': 'ABC', 'miRol': 'HABITANTE', 'miembros': []};
    responses['/salas/unirse'] = {'id': 8};
    final sent = <String, Object?>{};
    final repo = await loggedIn(sent);

    expect(await repo.getHouses(), [(id: 7, name: 'Casa 304'), (id: 8, name: 'Depa')]);
    await repo.join('ABC');
    expect(sent['POST /salas/unirse'], {'codigo': 'ABC'});
    expect((await repo.getCurrentHouse())!.name, 'Depa');

    repo.select(99);
    expect((await repo.getCurrentHouse())!.name, 'Casa 304');
  });
}
