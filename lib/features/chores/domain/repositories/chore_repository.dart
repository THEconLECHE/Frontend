import '../entities/chore.dart';

abstract interface class ChoreRepository {
  // Lanza AuthException con un mensaje para el usuario
  Future<List<Chore>> getChores(int houseId);

  // Solo el admin y el backend la asigna en la siguiente vuelta
  Future<void> addChore(int houseId, String title, String? description, ChoreFrequency frequency, int points);

  // Hecha no se puede deshacer porque los puntos ya se contaron
  Future<void> completeChore(int id);

  // Los puntos de cada miembro en este trimestre por nombre
  Future<Map<String, int>> getPoints(int houseId);
}
