import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://192.168.100.75:3000/api';

class DioClient {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  DioClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // Cambiamos onRequest a asíncrono para poder leer el disco
        onRequest: (options, handler) async {
          // Inyectamos el Token real en todas las peticiones (excepto Login y Registro)
          if (!options.path.contains('/login') &&
              !options.path.contains('/register')) {
            final token = await _storage.read(key: 'jwt_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          print('🌐 PETICIÓN [${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ RESPUESTA [${response.statusCode}] => DATA: ${response.data}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Si el response es null, mostramos el tipo de error (ej. Timeout)
          final statusCode = e.response?.statusCode ?? 'SIN CONEXIÓN';
          final errorMessage = e.response?.data ?? e.message;
          print('❌ ERROR [$statusCode] => MENSAJE: $errorMessage');
          return handler.next(e);
        },
      ),
    );
  }

  // Permite acceso directo a la instancia de Dio
  Dio get instance => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
}

final dioProvider = Provider<DioClient>((ref) {
  return DioClient();
});
