import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/member_avatar.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/text_prompt.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/logout.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/edit_name.dart';
import '../../domain/usecases/get_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.getProfile,
    required this.editName,
    required this.deleteAccount,
    required this.logout,
  });

  final GetProfile getProfile;
  final EditName editName;
  final DeleteAccount deleteAccount;
  final Logout logout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Los dos son null mientras carga
  Profile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.getProfile();
      if (mounted) setState(() => _profile = profile);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _retry() {
    setState(() => _error = null);
    _load();
  }

  // La sesion termino y regresa al login
  Future<void> _run(Future<void> Function() action, {bool exit = false}) async {
    try {
      await action();
      if (!mounted) return;
      if (exit) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      } else {
        await _load();
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _edit(String current) async {
    final name = await promptText(
      context,
      title: 'Editar nombre',
      label: 'Nombre',
      action: 'Guardar',
      empty: 'Escribe tu nombre',
      initial: current,
      maxLength: 60,
    );
    if (name != null && name != current) await _run(() => widget.editName(name));
  }

  Future<void> _delete() async {
    if (await confirm(context, 'Eliminar cuenta', 'Se borra tu cuenta y no se puede deshacer.', 'Eliminar',
        destructive: true)) {
      await _run(widget.deleteAccount.call, exit: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error),
            const SizedBox(height: 8),
            FilledButton(onPressed: _retry, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    final profile = _profile;
    if (profile == null) return const Center(child: CircularProgressIndicator());
    final admin = profile.houses.where((h) => h.isAdmin).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        const PageTitle('Perfil'),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: MemberAvatar(profile.name),
            title: Text(profile.name),
            subtitle: Text(profile.email),
            trailing: IconButton(
              tooltip: 'Editar nombre',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(profile.name),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Información general', style: Theme.of(context).textTheme.titleMedium),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text('${profile.houses.length}'),
                subtitle: const Text('Salas a las que perteneces'),
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text('$admin'),
                subtitle: const Text('Salas que administras'),
              ),
              for (final house in profile.houses)
                ListTile(
                  dense: true,
                  title: Text(house.name),
                  trailing: Chip(label: Text(house.isAdmin ? 'Admin' : 'Habitante')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _run(widget.logout.call, exit: true),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}
