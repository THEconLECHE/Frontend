import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_roomiehub/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_roomiehub/features/chores/data/repositories/http_chore_repository.dart';
import 'package:flutter_roomiehub/features/chores/domain/entities/chore.dart';

void main() {
  test('chores are the house\'s current turns; creating and completing hit their endpoints', () async {
    final sent = <String, Object?>{};
    final auth = HttpAuthRepository(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        sent['${req.method} ${req.url.path}'] = req.body.isEmpty ? null : jsonDecode(req.body);
        return http.Response(
          jsonEncode(switch (req.url.path) {
            '/auth/login' => {
              'accessToken': 'jwt',
              'refreshToken': 'r',
              'usuario': {'id': 1, 'nombre': 'Ana'},
            },
            '/salas/7/asignaciones' => [
              {
                'id': 5,
                'tareaId': 1,
                'tarea': 'Basura',
                'responsable': 'Ana',
                'estado': 'COMPLETADA',
                'valor': 2,
                'periodoFin': '2026-11-03T06:00:00Z',
              },
              {
                'id': 6,
                'tareaId': 2,
                'tarea': 'Platos',
                'responsable': null,
                'estado': 'ASIGNADA',
                'valor': 4,
                'periodoFin': '2026-11-03T06:00:00Z',
              },
            ],
            '/salas/7/tareas' when req.method == 'GET' => [
              {'id': 1, 'nombre': 'Basura', 'descripcion': 'Los martes', 'valor': 2, 'frecuencia': 'P9D'},
              {'id': 2, 'nombre': 'Platos', 'descripcion': null, 'valor': 4, 'frecuencia': 'P1M'},
              {'id': 3, 'nombre': 'Trapear', 'descripcion': null, 'valor': 3, 'frecuencia': 'P7D'},
            ],
            '/salas/7/balance' => [
              {'usuarioId': 1, 'nombre': 'Ana', 'visible': 6, 'historico': 20},
            ],
            _ => {'id': 9},
          }),
          200,
          // El backend manda UTF 8 y sin charset el mock mandaria Latin 1
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await auth.login('ana@mail.com', 'x');
    final repo = HttpChoreRepository(auth);

    final chores = await repo.getChores(7);
    expect(
      [for (final c in chores) (c.id, c.title, c.assignee, c.done, c.queued)],
      [
        (5, 'Basura', 'Ana', true, false),
        (6, 'Platos', null, false, false),
        // Sin turno se muestra para que la tarea nueva no desaparezca
        (3, 'Trapear', null, false, true),
      ],
    );
    // Los detalles vienen del catalogo
    final basura = chores.first;
    expect((basura.description, basura.frequency?.label, basura.points), ('Los martes', 'Cada 9 días', 2));
    expect(chores[1].frequency?.label, 'Mensual');
    // El turno termina cuando empieza el siguiente y su ultimo dia es el anterior
    expect(basura.lastDay, DateTime.utc(2026, 11, 3, 6).toLocal().subtract(const Duration(seconds: 1)));

    await repo.addChore(7, 'Trapear', 'Con el trapeador azul', const ChoreFrequency.everyDays(5), 4);
    final body = sent['POST /salas/7/tareas'] as Map;
    expect(
      [body['nombre'], body['descripcion'], body['valor'], body['frecuencia']],
      ['Trapear', 'Con el trapeador azul', 4, 'P5D'],
    );
    expect(body['fechaInicio'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));

    await repo.addChore(7, 'Cortinas', null, const ChoreFrequency.monthly(), 2);
    expect((sent['POST /salas/7/tareas'] as Map)['frecuencia'], 'P1M');

    await repo.completeChore(6);
    expect(sent.keys, contains('POST /asignaciones/6/completar'));

    // Los puntos del trimestre y no los de siempre
    expect(await repo.getPoints(7), {'Ana': 6});
  });
}
