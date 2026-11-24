import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/text_prompt.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../house/domain/entities/house.dart';
import '../../../house/domain/usecases/create_house.dart';
import '../../../house/domain/usecases/get_current_house.dart';
import '../../../house/domain/usecases/get_houses.dart';
import '../../../house/domain/usecases/join_house.dart';
import '../../../house/domain/usecases/leave_house.dart';
import '../../../house/domain/usecases/select_house.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.finances,
    required this.board,
    required this.chores,
    required this.chat,
    required this.profile,
    required this.getCurrentHouse,
    required this.leaveHouse,
    required this.getHouses,
    required this.selectHouse,
    required this.joinHouse,
    required this.createHouse,
    required this.adminPage,
  });

  /* Se inyecta para que el shell no dependa de como cada seccion trae sus datos
     las secciones se crean para la casa actual y de nuevo al cambiar de casa */
  final Widget Function(House house) finances;
  final Widget Function(House house) board;
  final Widget Function(House house) chores;
  final Widget Function(House house) chat;
  final Widget profile;
  final GetCurrentHouse getCurrentHouse;
  final LeaveHouse leaveHouse;
  final GetHouses getHouses;
  final SelectHouse selectHouse;
  final JoinHouse joinHouse;
  final CreateHouse createHouse;
  final Widget Function(House house) adminPage;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _boardTab = 2;
  int _tab = _boardTab;
  // null mientras carga o si el usuario no esta en ninguna casa
  House? _house;
  // true cuando el backend respondio y si falla las pestañas siguen sirviendo
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadHouse();
  }

  Future<void> _loadHouse() async {
    try {
      final house = await widget.getCurrentHouse();
      if (mounted) {
        setState(() {
          _house = house;
          _loaded = true;
        });
      }
    } on AuthException catch (e) {
      _show(e.message);
    }
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onMenu(String option) async {
    final house = _house;
    if (house == null) return;
    switch (option) {
      case 'share':
        await _share(house);
      case 'leave':
        if (!await confirm(context, 'Dejar sala', '¿Salir de ${house.name}?', 'Salir')) return;
        await _run(() => widget.leaveHouse(house.id), 'Saliste de ${house.name}');
      case 'admin':
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => widget.adminPage(house)));
        await _loadHouse();
    }
  }

  // Muestra done y recarga si la accion funciona y si no muestra el error
  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      _show(done);
      await _loadHouse();
    } on AuthException catch (e) {
      _show(e.message);
    }
  }

  Future<void> _switchHouse() async {
    final List<({int id, String name})> houses;
    try {
      houses = await widget.getHouses();
    } on AuthException catch (e) {
      return _show(e.message);
    }
    if (!mounted) return;
    // Menos uno significa unirse o crear
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final h in houses)
              ListTile(
                leading: const Icon(Icons.house_outlined),
                title: Text(h.name),
                trailing: h.id == _house?.id ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(context, h.id),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_home_outlined),
              title: const Text('Unirme o crear sala'),
              onTap: () => Navigator.pop(context, -1),
            ),
          ],
        ),
      ),
    );
    if (picked == null || picked == _house?.id) return;
    if (picked == -1) return _addHouse();
    widget.selectHouse(picked);
    await _loadHouse();
  }

  Future<void> _addHouse() async {
    final create = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key_outlined),
              title: const Text('Unirme con código'),
              onTap: () => Navigator.pop(context, false),
            ),
            ListTile(
              leading: const Icon(Icons.add_home_outlined),
              title: const Text('Crear sala'),
              onTap: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );
    if (create == null || !mounted) return;
    if (create) {
      final name = await promptText(context,
          title: 'Crear sala', label: 'Nombre', action: 'Crear', empty: 'Escribe el nombre', maxLength: 60);
      if (name != null) await _run(() => widget.createHouse(name), 'Sala $name creada');
    } else {
      final code = await promptText(context,
          title: 'Unirme con código', label: 'Código de invitación', action: 'Unirme', empty: 'Escribe el código');
      if (code != null) await _run(() => widget.joinHouse(code), '¡Bienvenido a tu nueva sala!');
    }
  }

  Future<void> _share(House house) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Compartir sala'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pasa este código a quien quieras invitar a ${house.name}:'),
              const SizedBox(height: 16),
              SelectableText(house.inviteCode, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: house.inviteCode));
                Navigator.pop(context);
                _show('Código copiado');
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final house = _house;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: house != null
            ? InkWell(
                onTap: _switchHouse,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(house.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 32),
                  ],
                ),
              )
            : _loaded
                ? IconButton(
                    onPressed: _addHouse,
                    tooltip: 'Unirme o crear sala',
                    icon: const Icon(Icons.add_home_outlined, size: 32),
                  )
                : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              tooltip: 'Opciones de sala',
              offset: const Offset(0, 56),
              onSelected: _onMenu,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'share',
                  enabled: house != null,
                  child: const ListTile(leading: Icon(Icons.link), title: Text('Compartir sala')),
                ),
                PopupMenuItem(
                  value: 'leave',
                  enabled: house != null,
                  child: const ListTile(leading: Icon(Icons.logout), title: Text('Dejar sala')),
                ),
                if (house != null && house.isAdmin)
                  const PopupMenuItem(
                    value: 'admin',
                    child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Administrar sala')),
                  ),
              ],
              icon: const Icon(Icons.more_vert, size: 28),
            ),
          ),
        ],
      ),
      body: switch (_tab) {
        // El perfil siempre se puede abrir porque salir y borrar cuenta no necesitan casa
        4 => widget.profile,
        _ when house == null => _loaded ? const _NoHouse() : const SizedBox.shrink(),
        _ => KeyedSubtree(
            key: ValueKey(house.id),
            child: switch (_tab) {
              0 => widget.finances(house),
              1 => widget.chores(house),
              _boardTab => widget.board(house),
              _ => widget.chat(house),
            },
          ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Finanzas'),
          NavigationDestination(icon: Icon(Icons.check_box_outlined), selectedIcon: Icon(Icons.check_box), label: 'Tareas'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Tablón'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _NoHouse extends StatelessWidget {
  const _NoHouse();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.house_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Únete a una sala para empezar tu convivencia 0_o',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Toca la casita de arriba para unirte o crear una', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
