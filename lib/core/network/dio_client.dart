import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Importante para detectar si es Debug o Release
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DioClient {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  String? _inMemoryToken;
  final VoidCallback? onUnauthorized;

  DioClient({this.onUnauthorized})
    : _dio = Dio(
        BaseOptions(
          baseUrl: dotenv.env['API_URL'] ?? '',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    // PRÁCTICA SENIOR: Los logs solo se inyectan si estás depurando.
    // Esto evita fugas de tokens, contraseñas y datos sensibles en producción.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // No inyectamos token en rutas públicas
          if (!options.path.contains('/login') &&
              !options.path.contains('/register')) {
            _inMemoryToken ??= await _storage.read(key: 'jwt_token');
            if (_inMemoryToken != null) {
              options.headers['Authorization'] = 'Bearer $_inMemoryToken';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Si el token expira o es inválido, matamos la sesión inmediatamente
          if (e.response?.statusCode == 401) {
            _inMemoryToken = null;
            await _storage.delete(key: 'jwt_token');
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
          // Propagamos el error para que AppException.fromDioException lo procese en los repositorios
          return handler.next(e);
        },
      ),
    );
  }

  Dio get instance => _dio;

  void clearTokenCache() {
    _inMemoryToken = null;
  }
}

final dioProvider = Provider<DioClient>((ref) {
  return DioClient(
    onUnauthorized: () {
      Future.microtask(() => ref.read(authProvider.notifier).logout());
    },
  );
});
