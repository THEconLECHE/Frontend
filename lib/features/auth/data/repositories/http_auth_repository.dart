import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/repositories/auth_repository.dart';

// Backend en Render y para usarlo local se pasa API_URL al correr la app
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://roomiehub-backend-mvg4.onrender.com');

const _refreshKey = 'refreshToken';

class HttpAuthRepository implements AuthRepository {
  /* Token de push de este telefono y null si no hay push como en los tests
     storage guarda el refresh token para no pedir login cada vez y null no guarda nada */
  HttpAuthRepository({http.Client? client, this.baseUrl = apiUrl, this._pushToken, this._storage})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Future<String?> Function()? _pushToken;
  final FlutterSecureStorage? _storage;

  String? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _fcmToken;
  Future<void>? _renewing;

  @override
  String? get currentUser => _user;

  @override
  Future<void> login(String email, String password) =>
      _startSession('/auth/login', {'email': email, 'contrasena': password});

  @override
  Future<void> register(String name, String email, String password) =>
      _startSession('/auth/registro', {'nombre': name, 'email': email, 'contrasena': password});

  @override
  Future<bool> restore() async {
    final saved = await _storage?.read(key: _refreshKey);
    if (saved == null) return false;
    try {
      await _startSession('/auth/refresh', {'refreshToken': saved});
      return true;
    } on AuthException catch (e) {
      // Sin red se guarda el token para intentar la proxima vez
      if (e.status == 401) await _storage?.delete(key: _refreshKey);
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final refresh = _refreshToken;
    final fcm = _fcmToken;
    _user = _accessToken = _refreshToken = _fcmToken = null;
    await _storage?.delete(key: _refreshKey);
    if (refresh == null) return;
    try {
      // Con el token el servidor deja de mandar push de esta cuenta a este telefono
      await _send('POST', '/auth/logout', {'refreshToken': refresh, 'fcmToken': ?fcm});
    } on AuthException {
      // Se cierra la sesion local aunque falle y el token del servidor expira solo
    }
  }

  // Si el token de acceso expiro se renueva una vez y se repite la llamada
  @override
  Future<Object?> request(String method, String path, [Map<String, Object?>? body]) async {
    final token = _accessToken;
    if (token == null) throw const AuthException('Inicia sesión de nuevo');
    try {
      return await _send(method, path, body, bearer: token);
    } on AuthException catch (e) {
      if (e.status != 401) rethrow;
      // Otra llamada pudo renovarlo ya
      if (_accessToken == token) await _renew();
      return _send(method, path, body, bearer: _accessToken);
    }
  }

  // Una sola renovacion a la vez porque el servidor cambia el refresh token en cada uso
  Future<void> _renew() => _renewing ??= _refresh().whenComplete(() => _renewing = null);

  Future<void> _refresh() async {
    final refresh = _refreshToken;
    if (refresh == null) throw const AuthException('Inicia sesión de nuevo');
    try {
      await _startSession('/auth/refresh', {'refreshToken': refresh}, registerDevice: false);
    } on AuthException catch (e) {
      if (e.status != 401) rethrow;
      _user = _accessToken = _refreshToken = null;
      await _storage?.delete(key: _refreshKey);
      throw const AuthException('Tu sesión expiró, inicia sesión de nuevo', status: 401);
    }
  }

  Future<void> _startSession(String path, Map<String, String> body, {bool registerDevice = true}) async {
    final session = await _send('POST', path, body) as Map<String, dynamic>;
    _accessToken = session['accessToken'] as String;
    _refreshToken = session['refreshToken'] as String;
    _user = (session['usuario'] as Map<String, dynamic>)['nombre'] as String;
    await _storage?.write(key: _refreshKey, value: _refreshToken);
    // No se espera para que el permiso no detenga al usuario en el login
    if (registerDevice) unawaited(_registerDevice());
  }

  /* shortcut solo se registra al iniciar sesion
     tambien escuchar onTokenRefresh cuando la sesion sobreviva al reinicio */
  Future<void> _registerDevice() async {
    try {
      final token = await _pushToken?.call();
      if (token == null) return;
      await _send('PUT', '/usuarios/yo/dispositivos',
          {'fcmToken': token, 'plataforma': Platform.isIOS ? 'IOS' : 'ANDROID'}, bearer: _accessToken);
      _fcmToken = token;
    } on Exception {
      // El push es opcional y la app funciona sin el
    }
  }

  Future<Object?> _send(String method, String path, Map<String, Object?>? body, {String? bearer}) async {
    final req = http.Request(method, Uri.parse('$baseUrl$path'));
    if (body != null) {
      req
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    if (bearer != null) req.headers['Authorization'] = 'Bearer $bearer';
    final http.Response res;
    try {
      // Tiempo largo porque Render tarda hasta un minuto en despertar
      res = await http.Response.fromStream(await _client.send(req).timeout(const Duration(seconds: 70)));
    } on Exception {
      throw const AuthException('No se pudo conectar con el servidor');
    }
    Object? json;
    try {
      json = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      json = null; // por ejemplo una pagina de error del proxy
    }
    if (res.statusCode >= 400) {
      final detail = json is Map ? json['detail'] : null;
      throw AuthException(
          switch (res.statusCode) {
            401 when bearer == null => 'Correo o contraseña incorrectos',
            401 => 'Tu sesión expiró, inicia sesión de nuevo',
            _ => detail is String ? detail : 'Error del servidor (${res.statusCode})',
          },
          status: res.statusCode);
    }
    return json;
  }
}
