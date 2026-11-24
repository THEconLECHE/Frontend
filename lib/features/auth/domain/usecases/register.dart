import '../repositories/auth_repository.dart';

class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<void> call(String name, String email, String password) =>
      _repository.register(name.trim(), email.trim(), password);
}
