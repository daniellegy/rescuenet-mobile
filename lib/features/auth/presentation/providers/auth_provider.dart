import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/auth_repository.dart';

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

  Future<void> _processAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'];
    final int rolId = data['usuario']['rol_id'];

    await _storage.write(key: 'jwt_token', value: token);

    AppRole userRole = AppRole.ninguno;
    if (rolId == 1) userRole = AppRole.reportante;
    if (rolId == 2) userRole = AppRole.voluntario;

    state = AuthState(isLogged: true, role: userRole);
  }

  Future<void> login(String email, String password) async {
    final authRepository = ref.read(authRepositoryProvider);
    final data = await authRepository.login(email, password);
    await _processAuthResponse(data);
  }

  Future<void> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
  }) async {
    final authRepository = ref.read(authRepositoryProvider);
    final data = await authRepository.register(
      nombre: nombre,
      telefono: telefono,
      email: email,
      password: password,
      rolId: rolId,
    );
    await _processAuthResponse(data);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    state = AuthState(isLogged: false, role: AppRole.ninguno);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
