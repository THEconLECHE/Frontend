class House {
  const House({required this.id, required this.name, required this.inviteCode, required this.isAdmin, required this.members});

  final int id;
  final String name;
  final String inviteCode;
  // Si el usuario actual administra esta casa
  final bool isAdmin;
  final List<Member> members;
}

class Member {
  const Member({required this.id, required this.name, required this.isAdmin});

  final int id;
  final String name;
  final bool isAdmin;
}
