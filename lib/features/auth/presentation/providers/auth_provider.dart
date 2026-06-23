import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart'; // IMPORTANTE: Necesario para capturar DioException
import 'dart:convert';
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
// mantener sesion iniciada al reiniciar la app
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

    return Map<String, dynamic>.from(payload as Map);
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

      if (usuario is! Map) {
        throw const FormatException('El token no contiene datos de usuario');
      }

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
        throw const FormatException('El token no contiene id o rol válidos');
      }

      state = AuthState(
        isLogged: true,
        role: _roleFromRolId(rolId),
        userId: userId,
      );

      if (state.role == AppRole.voluntario) {
        await FirebaseMessaging.instance.subscribeToTopic('voluntarios');
      } else if (state.role == AppRole.reportante) {
        await FirebaseMessaging.instance.unsubscribeFromTopic('voluntarios');
      }
    } catch (_) {
      await _storage.delete(key: 'jwt_token');
      state = AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
    }
  }
//
  Future<void> _processAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'];
    final int rolId = data['usuario']['rol_id'];
    final int idUsuario = data['usuario']['id'];

    await _storage.write(key: 'jwt_token', value: token);

    AppRole userRole = AppRole.ninguno;
    if (rolId == 1) {
      userRole = AppRole.reportante;
      await FirebaseMessaging.instance.unsubscribeFromTopic('voluntarios');
    }
    if (rolId == 2) {
      userRole = AppRole.voluntario;
      await FirebaseMessaging.instance.subscribeToTopic('voluntarios');
    }

    state = AuthState(isLogged: true, role: userRole, userId: idUsuario);
  }

  Future<void> login(String email, String password) async {
    try {
      final dio = ref.read(dioProvider).instance;
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      if (response.statusCode == 200) await _processAuthResponse(response.data);
    } on DioException catch (e) {
      // Capturamos el mensaje exacto que manda Node.js (ej: "Credenciales inválidas")
      throw Exception(
        e.response?.data['error'] ?? 'Error de conexión al iniciar sesión',
      );
    } catch (e) {
      throw Exception('Ocurrió un error inesperado');
    }
  }

  Future<void> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
    String? curp,
  }) async {
    try {
      final dio = ref.read(dioProvider).instance;
      final response = await dio.post(
        '/auth/register',
        data: {
          'nombre_completo': nombre,
          'telefono': telefono,
          'email': email,
          'password': password,
          'rol_id': rolId,
          'curp': curp,
        },
      );
      if (response.statusCode == 201) await _processAuthResponse(response.data);
    } on DioException catch (e) {
      // Capturamos el mensaje exacto (ej: "El correo ya está registrado")
      throw Exception(
        e.response?.data['error'] ?? 'Error al registrar usuario',
      );
    } catch (e) {
      throw Exception('Ocurrió un error inesperado');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState(isLogged: false, role: AppRole.ninguno, userId: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
