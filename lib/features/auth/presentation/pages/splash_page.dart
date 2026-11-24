import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/usecases/restore_session.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.restoreSession});

  final RestoreSession restoreSession;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  // Con sesion guardada entra directo al inicio y si no va al login
  Future<void> _start() async {
    final (loggedIn, _) = await (widget.restoreSession(), Future.delayed(const Duration(milliseconds: 1500))).wait;
    if (mounted) Navigator.of(context).pushReplacementNamed(loggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'RoomieHub',
          style: TextStyle(fontSize: 52, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
