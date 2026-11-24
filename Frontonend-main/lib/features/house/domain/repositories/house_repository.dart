import '../entities/house.dart';

abstract interface class HouseRepository {
  /* null mientras el usuario no esta en ninguna casa
     todos lanzan AuthException con un mensaje para el usuario */
  Future<House?> getCurrentHouse();

  // Todas las casas del usuario para cambiar entre ellas
  Future<List<({int id, String name})>> getHouses();

  // Hace que houseId sea la casa actual
  void select(int houseId);

  // Los dos hacen que la casa nueva sea la actual
  Future<void> join(String code);

  Future<void> create(String name);

  Future<void> leave(int houseId);

  // Solo el admin
  Future<void> expel(int houseId, int userId);

  // Solo el admin y el usuario actual deja de ser admin
  Future<void> transferAdmin(int houseId, int userId);

  // Solo el admin
  Future<void> deactivate(int houseId);
}
