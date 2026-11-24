import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email, String password) => _repository.login(email.trim(), password);
}
