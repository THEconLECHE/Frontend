import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/profile/data/repositories/http_profile_repository.dart';

void main() {
  test('profile lists every house with the user\'s role, and edits the name', () async {
    final sent = <String, Object?>{};
    final responses = {
      '/auth/login': {
        'accessToken': 'jwt',
        'refreshToken': 'refresh-1',
        'usuario': {'id': 1, 'nombre': 'Ana', 'email': 'ana@mail.com', 'fotoUrl': null},
      },
      '/usuarios/yo': {'id': 1, 'nombre': 'Ana', 'email': 'ana@mail.com', 'fotoUrl': null},
      '/salas': [
        {'id': 7, 'nombre': 'Casa 304', 'miRol': 'ADMIN'},
        {'id': 8, 'nombre': 'Depa', 'miRol': 'HABITANTE'},
      ],
    };
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        if (req.url.path != '/auth/login') expect(req.headers['Authorization'], 'Bearer jwt');
        sent['${req.method} ${req.url.path}'] = req.body.isEmpty ? null : jsonDecode(req.body);
        return http.Response(jsonEncode(responses[req.url.path]), 200);
      }),
    );
    await auth.login('ana@mail.com', 'secreta123');
    final repo = HttpProfileRepository(auth);

    final profile = await repo.getProfile();
    expect(profile.name, 'Ana');
    expect(profile.email, 'ana@mail.com');
    expect(profile.houses, [(name: 'Casa 304', isAdmin: true), (name: 'Depa', isAdmin: false)]);

    await repo.editName('Ana María');
    expect(sent['PUT /usuarios/yo'], {'nombre': 'Ana María'});
  });
}
