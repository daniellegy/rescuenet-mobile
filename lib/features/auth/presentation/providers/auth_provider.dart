import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../data/auth_repository.dart';
import '../../../../core/network/dio_client.dart';

enum AppRole { ninguno, reportante, voluntario, refugio, superadmin }

class AuthState {
  final bool isLogged;
  final AppRole role;
  final int? userId;

  AuthState({this.isLogged = false, this.role = AppRole.ninguno, this.userId});
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    return AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
  }

  AppRole _roleFromRolId(int rolId) {
    if (rolId == 1) return AppRole.reportante;
    if (rolId == 2) return AppRole.voluntario;
    return AppRole.ninguno;
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token JWT inválido');
    }

    final normalizedPayload = base64Url.normalize(parts[1]);
    final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
    final payload = jsonDecode(decodedPayload);

    if (payload is! Map) {
      throw const FormatException('El payload del token no es un objeto JSON');
    }

    return Map<String, dynamic>.from(payload);
  }

  Future<void> restoreSession() async {
    final token = await _storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      state = AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
      return;
    }

    try {
      final payload = _decodeJwtPayload(token);
      final usuario = payload['usuario'];

      if (usuario is! Map) throw const FormatException('Sin datos de usuario');

      final userId = usuario['id'];
      final rolId = usuario['rol_id'];
      final exp = payload['exp'];

      if (exp is int) {
        final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (expirationDate.isBefore(DateTime.now())) {
          await logout();
          return;
        }
      }

      if (userId is! int || rolId is! int) {
        throw const FormatException('Id o rol inválidos');
      }

      state = AuthState(
        isLogged: true,
        role: _roleFromRolId(rolId),
        userId: userId,
      );

      // SE ELIMINÓ: _actualizarFCMToken() automático.
      // Las notificaciones dependen exclusivamente de la preferencia guardada en el backend.
    } catch (_) {
      await _storage.delete(key: 'jwt_token');
      state = AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
    }
  }

  Future<void> _processAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'];
    final int rolId = data['usuario']['rol_id'];
    final int idUsuario = data['usuario']['id'];

    await _storage.write(key: 'jwt_token', value: token);

    AppRole userRole = AppRole.ninguno;
    if (rolId == 1) userRole = AppRole.reportante;
    if (rolId == 2) userRole = AppRole.voluntario;

    state = AuthState(isLogged: true, role: userRole, userId: idUsuario);
    // SE ELIMINÓ: _actualizarFCMToken() automático.
  }

  Future<void> login(String email, String password) async {
    final repository = ref.read(authRepositoryProvider);
    final data = await repository.login(email, password);
    await _processAuthResponse(data);
  }

  Future<void> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
    String? curp,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final data = await repository.register(
      nombre: nombre,
      telefono: telefono,
      email: email,
      password: password,
      rolId: rolId,
      curp: curp,
    );
    await _processAuthResponse(data);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    ref.read(dioProvider).clearTokenCache();
    state = AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
  }

  Future<void> eliminarCuentaEnServidor() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) throw Exception('No hay una sesión activa.');

    final repository = ref.read(authRepositoryProvider);
    
    await repository.eliminarCuenta(token);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
