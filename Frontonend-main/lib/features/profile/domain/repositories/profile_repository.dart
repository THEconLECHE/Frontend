import '../entities/profile.dart';

abstract interface class ProfileRepository {
  // Todos lanzan AuthException con un mensaje para el usuario si fallan
  Future<Profile> getProfile();

  Future<void> editName(String name);

  // Tambien cierra la sesion en este telefono
  Future<void> deleteAccount();
}
