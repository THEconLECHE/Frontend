import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.login, required this.register});

  final Login login;
  final Register register;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (_registering) {
        await widget.register(_name.text, _email.text, _password.text);
      } else {
        await widget.login(_email.text, _password.text);
      }
      if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthException catch (e) {
      if (mounted) _show(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    Text(_registering ? 'Crear cuenta' : 'Iniciar sesión',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),
                    if (_registering)
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        maxLength: 60,
                        validator: required,
                      ),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => required(v) ?? (v!.contains('@') ? null : 'Correo inválido'),
                    ),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                          tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      obscureText: !_showPassword,
                      autofillHints: [_registering ? AutofillHints.newPassword : AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      // El backend pide al menos 8 caracteres solo al registrarse
                      validator: (v) => required(v) ??
                          (_registering && v!.length < 8 ? 'Al menos 8 caracteres' : null),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: _busy
                          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                          : Text(_registering ? 'Crear cuenta' : 'Entrar', style: const TextStyle(fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _registering = !_registering),
                      child: Text(_registering ? 'Ya tengo cuenta' : '¿No tienes cuenta? Crear una'),
                    ),
                    if (!_registering)
                      TextButton(
                        onPressed: () => _show('Recuperar contraseña: próximamente'),
                        child: const Text('Olvidé mi contraseña'),
                      ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => _show('Google: próximamente'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text('Iniciar sesión con Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
