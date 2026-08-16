import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory AppException.fromDioException(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('error') && data['error'] != null) {
        return AppException(
          data['error'].toString(),
          statusCode: e.response?.statusCode,
        );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          'El servidor tardó mucho en responder. Revisa tu conexión a internet.',
        );
      case DioExceptionType.badResponse:
        return AppException(
          'Error interno del servidor (${e.response?.statusCode}). Intenta más tarde.',
        );
      case DioExceptionType.cancel:
        return AppException('La petición fue cancelada.');
      case DioExceptionType.connectionError:
        return AppException(
          'No hay conexión a internet. Verifica tus datos o Wi-Fi.',
        );
      default:
        return AppException(
          'Ocurrió un error inesperado al conectar con el servidor.',
        );
    }
  }
}
