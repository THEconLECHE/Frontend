import '../../domain/repositories/auth_repository.dart';

// Para tests acepta cualquier correo y contraseña sin backend
class FakeAuthRepository implements AuthRepository {
  String? _user;

  @override
  String? get currentUser => _user;

  @override
  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) throw const AuthException('Correo o contraseña incorrectos');
    _user = email;
  }

  @override
  Future<void> register(String name, String email, String password) async => _user = name;

  @override
  Future<bool> restore() async => false;

  @override
  Future<void> logout() async => _user = null;

  @override
  Future<Object?> request(String method, String path, [Map<String, Object?>? body]) async => throw const AuthException('Sin servidor en las pruebas');
}
