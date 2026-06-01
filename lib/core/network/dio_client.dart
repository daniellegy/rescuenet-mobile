import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Esta será la IP de la computadora de tu compañero Web (ej. 192.168.1.X:3000)
// Por ahora usamos localhost genérico
const String baseUrl = 'http://10.0.2.2:3000/api';

class DioClient {
  final Dio _dio;

  DioClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(
            seconds: 10,
          ), // Si tarda más de 10s, lanza error
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // Agregamos Interceptores (Para ver qué pasa en consola y manejar Tokens)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: Leer el Token real guardado (ej. SharedPreferences o FlutterSecureStorage)
          const fakeToken = "ey123456789...";

          // Inyectamos el Token en todas las peticiones (excepto Login y Registro)
          if (!options.path.contains('/login') &&
              !options.path.contains('/register')) {
            options.headers['Authorization'] = 'Bearer $fakeToken';
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
          print('❌ ERROR [${e.response?.statusCode}] => MENSAJE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  // Métodos expuestos (GET, POST, PUT, DELETE)
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

// Exponemos el cliente a toda la app mediante Riverpod
final dioProvider = Provider<DioClient>((ref) {
  return DioClient();
});
