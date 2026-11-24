import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/house.dart';
import '../../domain/repositories/house_repository.dart';

class HttpHouseRepository implements HouseRepository {
  HttpHouseRepository(this._auth, [this._storage]);

  final AuthRepository _auth;
  // Guarda la casa elegida para abrir en ella al volver a la app
  final FlutterSecureStorage? _storage;
  static const _selectedKey = 'sala';
  // null es la primera casa
  int? _selected;

  @override
  Future<House?> getCurrentHouse() async {
    _selected ??= int.tryParse(await _savedHouse() ?? '');
    final houses = await getHouses();
    // La casa elegida a menos que el usuario la haya dejado
    final current = houses.where((h) => h.id == _selected).firstOrNull ?? houses.firstOrNull;
    if (current == null) return null;
    // La lista no trae miembros y el detalle si
    final house = await _auth.request('GET', '/salas/${current.id}') as Map<String, dynamic>;
    return House(
      id: house['id'] as int,
      name: house['nombre'] as String,
      inviteCode: house['codigoInvitacion'] as String,
      isAdmin: house['miRol'] == 'ADMIN',
      members: [
        for (final m in (house['miembros'] as List).cast<Map<String, dynamic>>())
          Member(id: m['usuarioId'] as int, name: m['nombre'] as String, isAdmin: m['rol'] == 'ADMIN'),
      ],
    );
  }

  @override
  Future<List<({int id, String name})>> getHouses() async => [
        for (final h in (await _auth.request('GET', '/salas') as List).cast<Map<String, dynamic>>())
          (id: h['id'] as int, name: h['nombre'] as String),
      ];

  // Si el almacenamiento falla se abre en la primera casa como antes
  Future<String?> _savedHouse() async {
    try {
      return await _storage?.read(key: _selectedKey);
    } on Exception {
      return null;
    }
  }

  @override
  void select(int houseId) {
    _selected = houseId;
    unawaited(_storage?.write(key: _selectedKey, value: '$houseId'));
  }

  @override
  Future<void> join(String code) async =>
      select((await _auth.request('POST', '/salas/unirse', {'codigo': code}) as Map)['id'] as int);

  /* shortcut todas las casas se crean con hora de Ciudad de Mexico
     pedir la zona cuando haya usuarios en otro lado */
  @override
  Future<void> create(String name) async => select(
      (await _auth.request('POST', '/salas', {'nombre': name, 'zonaHoraria': 'America/Mexico_City'}) as Map)['id']
          as int);

  @override
  Future<void> leave(int houseId) => _auth.request('DELETE', '/salas/$houseId/membresia');

  @override
  Future<void> expel(int houseId, int userId) => _auth.request('DELETE', '/salas/$houseId/miembros/$userId');

  @override
  Future<void> transferAdmin(int houseId, int userId) =>
      _auth.request('POST', '/salas/$houseId/administrador', {'usuarioId': userId});

  @override
  Future<void> deactivate(int houseId) => _auth.request('POST', '/salas/$houseId/desactivar');
}
