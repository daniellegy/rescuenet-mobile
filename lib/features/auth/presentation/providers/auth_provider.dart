import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart'; // Importamos Dio

enum AppRole { ninguno, cliente, voluntario, refugio, superadmin }

class AuthState {
  final bool isLogged;
  final AppRole role;

  AuthState({this.isLogged = false, this.role = AppRole.ninguno});
}

// 1. Modificamos el Notifier para que reciba el Ref de Riverpod
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(isLogged: false, role: AppRole.ninguno);
  }

  // 2. Modificamos la función de login
  Future<void> login(String email, String password) async {
    try {
      // Obtenemos el cliente Dio desde Riverpod
      final dio = ref.read(dioProvider);

      // Hacemos la petición POST al servidor simulado
      print('Intentando conectar con el servidor web...');

      // ESTA LÍNEA FALLARÁ a propósito porque el backend aún no existe,
      // pero es el código exacto que usarás cuando esté listo.
      /*
      final response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      */

      // Simulamos la carga temporalmente mientras tus compañeros web terminan
      await Future.delayed(const Duration(seconds: 2));

      state = AuthState(isLogged: true, role: AppRole.voluntario);
    } catch (e) {
      print('Error en el login: $e');
      // Aquí podrías cambiar el estado para mostrar un mensaje de error en la UI
    }
  }

  void logout() {
    state = AuthState(isLogged: false, role: AppRole.ninguno);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
