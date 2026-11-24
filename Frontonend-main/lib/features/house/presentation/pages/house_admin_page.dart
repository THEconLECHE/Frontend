import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/member_avatar.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/house.dart';
import '../../domain/usecases/deactivate_house.dart';
import '../../domain/usecases/expel_member.dart';
import '../../domain/usecases/get_current_house.dart';
import '../../domain/usecases/transfer_admin.dart';

// Solo la abre el admin y el backend lo revisa otra vez en cada accion
class HouseAdminPage extends StatefulWidget {
  const HouseAdminPage({
    super.key,
    required this.house,
    required this.getCurrentHouse,
    required this.expelMember,
    required this.transferAdmin,
    required this.deactivateHouse,
  });

  final House house;
  final GetCurrentHouse getCurrentHouse;
  final ExpelMember expelMember;
  final TransferAdmin transferAdmin;
  final DeactivateHouse deactivateHouse;

  @override
  State<HouseAdminPage> createState() => _HouseAdminPageState();
}

class _HouseAdminPageState extends State<HouseAdminPage> {
  late House _house = widget.house;

  // Se cierra porque despues el usuario ya no administra la casa
  Future<void> _run(Future<void> Function() action, {bool close = false}) async {
    try {
      await action();
      if (!mounted) return;
      if (close) return Navigator.pop(context);
      final house = await widget.getCurrentHouse();
      if (mounted && house != null) setState(() => _house = house);
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _onMember(String option, Member member) async {
    if (option == 'admin') {
      if (await confirm(context, 'Transferir administración', '${member.name} será el admin y tú dejarás de serlo.', 'Transferir')) {
        await _run(() => widget.transferAdmin(_house.id, member.id), close: true);
      }
    } else if (await confirm(context, 'Expulsar', '¿Sacar a ${member.name} de la sala?', 'Expulsar')) {
      await _run(() => widget.expelMember(_house.id, member.id));
    }
  }

  Future<void> _deactivate() async {
    if (await confirm(context, 'Desactivar sala', 'Nadie podrá usar ${_house.name} hasta que la reactives.', 'Desactivar')) {
      await _run(() => widget.deactivateHouse(_house.id), close: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar sala')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('Miembros (${_house.members.length})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final member in _house.members)
            Card(
              child: ListTile(
                leading: MemberAvatar(member.name),
                title: Text(member.name),
                subtitle: Text(member.isAdmin ? 'Admin' : 'Habitante'),
                trailing: member.isAdmin
                    ? null
                    : PopupMenuButton<String>(
                        tooltip: 'Opciones de ${member.name}',
                        onSelected: (option) => _onMember(option, member),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'admin', child: Text('Hacer admin')),
                          PopupMenuItem(value: 'expel', child: Text('Expulsar')),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _deactivate,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.block),
            label: const Text('Desactivar sala'),
          ),
        ],
      ),
    );
  }
}
