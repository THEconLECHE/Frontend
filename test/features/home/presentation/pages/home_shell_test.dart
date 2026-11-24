import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_roomiehub/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_roomiehub/features/home/presentation/pages/home_shell.dart';
import 'package:flutter_roomiehub/features/house/domain/entities/house.dart';
import 'package:flutter_roomiehub/features/house/domain/repositories/house_repository.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/create_house.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/get_current_house.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/get_houses.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/join_house.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/leave_house.dart';
import 'package:flutter_roomiehub/features/house/domain/usecases/select_house.dart';

// Empieza sin casa y el codigo JOINME une a Depa y una casa nueva tiene id 2
class _Houses implements HouseRepository {
  final _houses = <({int id, String name})>[];
  int? _selected;

  @override
  Future<House?> getCurrentHouse() async {
    final h = _houses.where((h) => h.id == _selected).firstOrNull;
    return h == null ? null : House(id: h.id, name: h.name, inviteCode: 'X', isAdmin: false, members: const []);
  }

  @override
  Future<List<({int id, String name})>> getHouses() async => _houses;

  @override
  void select(int houseId) => _selected = houseId;

  @override
  Future<void> join(String code) async {
    if (code != 'JOINME') throw const AuthException('Código inválido');
    _houses.add((id: 1, name: 'Depa'));
    select(1);
  }

  @override
  Future<void> create(String name) async {
    _houses.add((id: 2, name: name));
    select(2);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Without a house: join button; with houses: the title switches between them', (tester) async {
    final repo = _Houses();
    await tester.pumpWidget(MaterialApp(
      home: HomeShell(
        finances: (_) => const Text('finances'),
        board: (h) => Text('board of ${h.name}'),
        chores: (_) => const Text('chores'),
        chat: (_) => const Text('chat'),
        profile: const Text('profile'),
        getCurrentHouse: GetCurrentHouse(repo),
        leaveHouse: LeaveHouse(repo),
        getHouses: GetHouses(repo),
        selectHouse: SelectHouse(repo),
        joinHouse: JoinHouse(repo),
        createHouse: CreateHouse(repo),
        adminPage: (_) => const SizedBox(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Únete a una sala para empezar tu convivencia 0_o'), findsOneWidget);
    expect(find.textContaining('board'), findsNothing);
    expect(find.text('RoomieHub'), findsNothing);

    // El perfil no necesita casa
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('profile'), findsOneWidget);
    await tester.tap(find.text('Tablón'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Unirme o crear sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unirme con código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'joinme ');
    await tester.tap(find.text('Unirme'));
    await tester.pumpAndSettle();
    expect(find.text('Depa'), findsOneWidget);
    expect(find.text('board of Depa'), findsOneWidget);

    await tester.tap(find.text('Depa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unirme o crear sala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear sala'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Casa');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsOneWidget);
    // El contenido cambia con la casa
    expect(find.text('board of Casa'), findsOneWidget);

    // Regresa a la primera casa desde el titulo
    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Depa'));
    await tester.pumpAndSettle();
    expect(find.text('Depa'), findsOneWidget);
    expect(find.text('Casa'), findsNothing);
    expect(find.text('board of Depa'), findsOneWidget);
  });
}
