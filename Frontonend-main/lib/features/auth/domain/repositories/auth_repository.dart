abstract interface class AuthRepository {
  // Los dos lanzan AuthException con un mensaje para el usuario si fallan
  Future<void> login(String email, String password);

  Future<void> register(String name, String email, String password);

  // Recupera la sesion guardada y regresa true si sigue valida
  Future<bool> restore();

  // Nombre del usuario o null si nadie inicio sesion
  String? get currentUser;

  Future<void> logout();

  // Llamada con sesion al backend y regresa el JSON o null si viene vacio
  Future<Object?> request(String method, String path, [Map<String, Object?>? body]);
}

class AuthException implements Exception {
  const AuthException(this.message, {this.status});

  final String message;

  // Codigo HTTP del error y null si no hubo respuesta
  final int? status;

  @override
  String toString() => message;
}
