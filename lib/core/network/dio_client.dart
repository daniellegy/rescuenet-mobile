import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
          if (e.response?.statusCode == 401) {
            _inMemoryToken = null;
            await _storage.delete(key: 'jwt_token');
            // Disparamos el callback para que Riverpod actualice la UI
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
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
      // Usamos microtask para evitar errores de actualización de estado mientras otros providers se construyen
      Future.microtask(() => ref.read(authProvider.notifier).logout());
    },
  );
});
