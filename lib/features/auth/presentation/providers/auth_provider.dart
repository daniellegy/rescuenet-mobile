import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/dio_client.dart';

enum AppRole { ninguno, reportante, voluntario, refugio, superadmin }

class AuthState {
  final bool isLogged;
  final AppRole role;
  AuthState({this.isLogged = false, this.role = AppRole.ninguno});
}

class AuthNotifier extends Notifier<AuthState> {
  final _storage = const FlutterSecureStorage();

  @override
  AuthState build() {
    return AuthState(isLogged: false, role: AppRole.ninguno);
  }

  // Función interna para mapear y guardar estado
  Future<void> _processAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'];
    final int rolId = data['usuario']['rol_id'];

    // Guardar el token en almacenamiento seguro
    await _storage.write(key: 'jwt_token', value: token);

    AppRole userRole = AppRole.ninguno;
    if (rolId == 1) userRole = AppRole.reportante;
    if (rolId == 2) userRole = AppRole.voluntario;

    state = AuthState(isLogged: true, role: userRole);
  }

  Future<void> login(String email, String password) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        await _processAuthResponse(response.data);
      }
    } catch (e) {
      throw Exception('Credenciales incorrectas');
    }
  }

  Future<void> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/auth/register',
        data: {
          'nombre_completo': nombre,
          'telefono': telefono,
          'email': email,
          'password': password,
          'rol_id': rolId,
        },
      );

      if (response.statusCode == 201) {
        await _processAuthResponse(response.data);
      }
    } catch (e) {
      throw Exception('Error al registrar usuario');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState(isLogged: false, role: AppRole.ninguno);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
