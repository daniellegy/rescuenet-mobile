import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';

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
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Error inesperado al intentar iniciar sesión');
    }
  }

  Future<Map<String, dynamic>> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required int rolId,
    String? curp,
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
          if (curp != null) 'curp': curp,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Error inesperado al registrar usuario');
    }
  }

  Future<void> eliminarCuenta(String token) async {
    try {
      await _dio.delete(
        '/auth/perfil',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Error inesperado al intentar dar de baja la cuenta');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioProvider);
  return AuthRepository(dioClient.instance);
});
