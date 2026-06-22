import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? 'Credenciales incorrectas');
    }
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'nombre_completo': nombre,
          'telefono': telefono,
          'email': email,
          'password': password,
          'rol_id': rolId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? 'Error al registrar usuario',
      );
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return AuthRepository(dioClient.instance);
});
