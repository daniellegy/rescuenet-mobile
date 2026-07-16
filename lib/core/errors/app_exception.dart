import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;

  /// Factory para centralizar el mapeo de errores de red en un solo lugar.
  /// Aplica el principio DRY (Don't Repeat Yourself).
  factory AppException.fromDioException(DioException e) {
    // 1. Errores controlados por tu Backend Node.js (Vienen en e.response.data['error'])
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('error') && data['error'] != null) {
        return AppException(
          data['error'].toString(),
          statusCode: e.response?.statusCode,
        );
      }
    }

    // 2. Errores a nivel de red, timeouts o caídas de servidor
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
