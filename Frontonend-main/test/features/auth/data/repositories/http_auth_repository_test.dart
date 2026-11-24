import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/auth/domain/repositories/auth_repository.dart';

void main() {
  final session = jsonEncode({
    'accessToken': 'jwt',
    'accesoExpiraEn': '2026-11-01T12:15:00Z',
    'refreshToken': 'refresh-1',
    'usuario': {'id': 1, 'nombre': 'Ana', 'email': 'ana@mail.com', 'fotoUrl': null},
  });

  test('login keeps the session and logout revokes the refresh token', () async {
    final calls = <String, Map<String, dynamic>>{};
    final repo = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        calls[req.url.path] = jsonDecode(req.body) as Map<String, dynamic>;
        return req.url.path == '/auth/login' ? http.Response(session, 200) : http.Response('', 204);
      }),
    );

    await repo.login('ana@mail.com', 'secreta123');
    expect(calls['/auth/login'], {'email': 'ana@mail.com', 'contrasena': 'secreta123'});
    expect(repo.currentUser, 'Ana');

    await repo.logout();
    expect(calls['/auth/logout'], {'refreshToken': 'refresh-1'});
    expect(repo.currentUser, isNull);
  });

  test('with push, login registers the phone and logout unregisters it', () async {
    final calls = <String, http.Request>{};
    final repo = HttpAuthRepository(
      baseUrl: 'http://api',
      pushToken: () async => 'fcm-1',
      client: MockClient((req) async {
        calls[req.url.path] = req;
        return req.url.path == '/auth/login' ? http.Response(session, 200) : http.Response('', 204);
      }),
    );

    await repo.login('ana@mail.com', 'secreta123');
    await pumpEventQueue(); // el telefono se registra en segundo plano
    final device = calls['/usuarios/yo/dispositivos']!;
    expect(device.method, 'PUT');
    expect(device.headers['Authorization'], 'Bearer jwt');
    expect(jsonDecode(device.body), {'fcmToken': 'fcm-1', 'plataforma': 'ANDROID'});

    await repo.logout();
    expect(jsonDecode(calls['/auth/logout']!.body), {'refreshToken': 'refresh-1', 'fcmToken': 'fcm-1'});
  });

  test('a push failure does not break the login', () async {
    final repo = HttpAuthRepository(
      baseUrl: 'http://api',
      pushToken: () async => throw Exception('sin Play Services'),
      client: MockClient((req) async => http.Response(session, 200)),
    );
    await repo.login('ana@mail.com', 'secreta123');
    await pumpEventQueue();
    expect(repo.currentUser, 'Ana');
  });

  test('errors come back as messages for the user', () async {
    Future<String> failWith(http.Response res) async {
      final repo = HttpAuthRepository(baseUrl: 'http://api', client: MockClient((_) async => res));
      try {
        await repo.login('ana@mail.com', 'x');
        return 'no error';
      } on AuthException catch (e) {
        return e.message;
      }
    }

    expect(await failWith(http.Response('{"detail":"Unauthorized"}', 401)), 'Correo o contraseña incorrectos');
    expect(await failWith(http.Response(jsonEncode({'detail': 'Demasiados intentos fallidos'}), 429)),
        'Demasiados intentos fallidos');
    expect(await failWith(http.Response('<html>Bad gateway</html>', 502)), 'Error del servidor (502)');

    final offline = HttpAuthRepository(
        baseUrl: 'http://api', client: MockClient((_) async => throw http.ClientException('sin red')));
    await expectLater(offline.login('a@b.c', 'x'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'No se pudo conectar con el servidor')));
  });

  test('the session survives closing the app and logout forgets it', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final sent = <String>[];
    HttpAuthRepository open() => HttpAuthRepository(
          baseUrl: 'http://api',
          storage: storage,
          client: MockClient((req) async {
            if (req.url.path == '/auth/refresh') sent.add(jsonDecode(req.body)['refreshToken'] as String);
            return req.url.path == '/auth/logout' ? http.Response('', 204) : http.Response(session, 200);
          }),
        );

    expect(await open().restore(), isFalse);
    await open().login('ana@mail.com', 'secreta123');

    final reopened = open();
    expect(await reopened.restore(), isTrue);
    expect(sent, ['refresh-1']);
    expect(reopened.currentUser, 'Ana');

    await reopened.logout();
    expect(await open().restore(), isFalse);
  });

  test('an expired access token is renewed once and the call repeated', () async {
    final renewed = jsonEncode({...jsonDecode(session) as Map, 'accessToken': 'jwt-2', 'refreshToken': 'refresh-2'});
    var refreshes = 0;
    final repo = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        if (req.url.path == '/auth/login') return http.Response(session, 200);
        if (req.url.path == '/auth/refresh') {
          refreshes++;
          return http.Response(renewed, 200);
        }
        return req.headers['Authorization'] == 'Bearer jwt-2' ? http.Response('[]', 200) : http.Response('', 401);
      }),
    );
    await repo.login('ana@mail.com', 'secreta123');

    expect(await Future.wait([repo.request('GET', '/salas'), repo.request('GET', '/salas')]), [[], []]);
    expect(refreshes, 1);
  });

  test('a rejected refresh token ends the session', () async {
    final repo = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async =>
          req.url.path == '/auth/login' ? http.Response(session, 200) : http.Response('', 401)),
    );
    await repo.login('ana@mail.com', 'secreta123');

    await expectLater(repo.request('GET', '/salas'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Tu sesión expiró, inicia sesión de nuevo')));
    expect(repo.currentUser, isNull);
  });
}
