import 'package:flutter/material.dart';

import '../../../../core/widgets/member_avatar.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/chore.dart';
import '../../domain/usecases/add_chore.dart';
import '../../domain/usecases/get_chores.dart';
import '../../domain/usecases/complete_chore.dart';
import '../../domain/usecases/get_points.dart';
import '../widgets/chore_details_dialog.dart';
import '../widgets/new_chore_dialog.dart';

class ChoresPage extends StatefulWidget {
  const ChoresPage({
    super.key,
    required this.houseId,
    required this.isAdmin,
    required this.getChores,
    required this.addChore,
    required this.completeChore,
    required this.getPoints,
    required this.getCurrentUser,
  });

  final int houseId;
  // Solo el admin crea tareas
  final bool isAdmin;
  final GetChores getChores;
  final AddChore addChore;
  final CompleteChore completeChore;
  final GetPoints getPoints;
  final GetCurrentUser getCurrentUser;

  @override
  State<ChoresPage> createState() => _ChoresPageState();
}

class _ChoresPageState extends State<ChoresPage> {
  // null mientras carga la primera vez
  List<Chore>? _chores;
  Map<String, int>? _points;
  var _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() => _run(() async {
    // Una tras otra porque wait envuelve el AuthException y _run no lo veria
    final chores = await widget.getChores(widget.houseId);
    final points = await widget.getPoints(widget.houseId);
    if (mounted) {
      setState(() {
        _chores = chores;
        _points = points;
      });
    }
  });

  Future<void> _add() async {
    final chore = await showDialog<NewChore>(context: context, builder: (_) => const NewChoreDialog());
    if (chore == null) return;
    await _run(() async {
      await widget.addChore(widget.houseId, chore.title, chore.description, chore.frequency, chore.points);
      _show('Tarea creada. Se asignará a alguien en unos minutos');
      await _load();
    });
  }

  Future<void> _complete(Chore chore) => _run(() async {
    await widget.completeChore(chore.id);
    await _load();
  });

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      _show(e.message);
    }
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    /* shortcut las tareas se emparejan por nombre y dos roomies con el mismo nombre las comparten
       usar usuarioId cuando la sesion guarde el id */
    final me = widget.getCurrentUser();
    final chores = _onlyMine ? _chores?.where((c) => c.assignee == me).toList() : _chores;
    // Pendientes primero y hechas al final
    final sorted = [...?chores?.where((c) => !c.done), ...?chores?.where((c) => c.done)];

    return Scaffold(
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
        children: [
          Row(
            children: [
              const Expanded(child: PageTitle('Tareas')),
              if (_points case final points?)
                Tooltip(
                  message: 'Tus puntos este trimestre',
                  child: Chip(
                    avatar: const Text('✰', style: TextStyle(fontSize: 18)),
                    label: Text('${points[me] ?? 0} pts'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Todas'), icon: Icon(Icons.home_outlined)),
              ButtonSegment(value: true, label: Text('Mis tareas'), icon: Icon(Icons.person_outline)),
            ],
            selected: {_onlyMine},
            onSelectionChanged: (s) => setState(() => _onlyMine = s.first),
          ),
          const SizedBox(height: 16),
          if (chores != null && chores.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(child: Text(_onlyMine ? 'No tienes tareas asignadas' : 'No hay tareas. ¡Casa en orden!')),
            ),
          for (final chore in sorted)
            Card(
              clipBehavior: Clip.antiAlias,
              // Al tocar la tarea se abren sus detalles y el responsable desliza para marcarla
              child: ListTile(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => ChoreDetailsDialog(
                    chore,
                    // Solo el responsable la marca y no se puede deshacer
                    onComplete: chore.done || chore.queued || chore.assignee != me ? null : () => _complete(chore),
                  ),
                ),
                // Amarillo espera verde hecha rojo pendiente y el subtitulo tambien lo dice
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: choreStatus(chore).color, shape: BoxShape.circle),
                ),
                leading: MemberAvatar(chore.assignee ?? '?'),
                title: Text(chore.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: chore.assignee ?? 'Sin asignar'),
                      TextSpan(
                        text: ' · ${choreStatus(chore).label}',
                        style: TextStyle(color: choreStatus(chore).color.shade800, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
