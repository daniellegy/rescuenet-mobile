import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Definimos los roles basados en tu esquema de base de datos
enum AppRole { ninguno, cliente, voluntario, refugio, superadmin }

// 2. Definimos la "Memoria" de la sesión
class AuthState {
  final bool isLogged;
  final AppRole role;

  AuthState({this.isLogged = false, this.role = AppRole.ninguno});
}

// 3. Creamos el "Cerebro" moderno usando Notifier (Riverpod 2.0+)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Este método define el estado inicial al abrir la app
    return AuthState(isLogged: false, role: AppRole.ninguno);
  }

  // Simulación de inicio de sesión
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    // Asignamos el nuevo estado directamente
    state = AuthState(isLogged: true, role: AppRole.voluntario);
  }

  // Función para cerrar sesión
  void logout() {
    state = AuthState(isLogged: false, role: AppRole.ninguno);
  }
}

// 4. Exponemos este cerebro usando NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
