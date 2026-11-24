import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class HttpProfileRepository implements ProfileRepository {
  const HttpProfileRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<Profile> getProfile() async {
    final me = await _auth.request('GET', '/usuarios/yo') as Map<String, dynamic>;
    final houses = (await _auth.request('GET', '/salas') as List).cast<Map<String, dynamic>>();
    return Profile(
      name: me['nombre'] as String,
      email: me['email'] as String,
      houses: [for (final h in houses) (name: h['nombre'] as String, isAdmin: h['miRol'] == 'ADMIN')],
    );
  }

  @override
  Future<void> editName(String name) => _auth.request('PUT', '/usuarios/yo', {'nombre': name});

  @override
  Future<void> deleteAccount() async {
    await _auth.request('DELETE', '/usuarios/yo');
    await _auth.logout();
  }
}
