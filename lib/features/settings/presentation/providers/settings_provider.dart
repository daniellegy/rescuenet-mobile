import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isLogged) return {};

    final dio = ref.read(dioProvider).instance;

    try {
      final response = await dio.get('/auth/perfil');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw AppException('No se pudo obtener el perfil del servidor');
      }
    } on DioException catch (e) {
      throw AppException(e.response?.data['error'] ?? 'Error de red');
    } catch (e) {
      throw AppException('Error de red al conectar con el backend');
    }
  }

  Future<void> actualizarCampo({
    String? telefono,
    String? email,
    int? role,
    String? curp,
    int? radioNotificaciones,
  }) async {
    final dio = ref.read(dioProvider).instance;

    try {
      final Map<String, dynamic> datosAActualizar = {};

      // CORRECCIÓN: Agregar llaves a todas las estructuras de control
      if (telefono != null) {
        datosAActualizar['telefono'] = telefono;
      }
      if (email != null) {
        datosAActualizar['email'] = email;
      }
      if (role != null) {
        datosAActualizar['role'] = role;
      }
      if (curp != null) {
        datosAActualizar['curp'] = curp;
      }
      if (radioNotificaciones != null) {
        datosAActualizar['radio_notificaciones'] = radioNotificaciones;
      }

      final response = await dio.put('/auth/perfil', data: datosAActualizar);
      if (response.statusCode == 200) {
        final datosActualizados =
            response.data['usuario'] as Map<String, dynamic>;
        state = AsyncData(datosActualizados);
      } else {
        throw AppException('El servidor rechazó la actualización del perfil');
      }
    } on DioException catch (e) {
      throw AppException(
        e.response?.data['error'] ?? 'Error al actualizar los datos',
      );
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al actualizar los datos');
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>>(() {
      return UserProfileNotifier();
    });
