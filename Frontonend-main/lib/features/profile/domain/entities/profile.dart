class Profile {
  const Profile({required this.name, required this.email, required this.houses});

  final String name;
  final String email;
  // Todas las casas del usuario
  final List<({String name, bool isAdmin})> houses;
}
