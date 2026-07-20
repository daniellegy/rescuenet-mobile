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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Error de red inesperado al cargar el perfil');
    }
  }

  Future<void> actualizarCampo({
    String? telefono,
    String? email,
    int? role,
    String? curp,
    int? radioNotificaciones,
    String? fcmToken,
  }) async {
    final dio = ref.read(dioProvider).instance;
    try {
      final Map<String, dynamic> datosAActualizar = {};
      if (telefono != null) datosAActualizar['telefono'] = telefono;
      if (email != null) datosAActualizar['email'] = email;
      if (role != null) datosAActualizar['role'] = role;
      if (curp != null) datosAActualizar['curp'] = curp;
      if (radioNotificaciones != null)
        datosAActualizar['radio_notificaciones'] = radioNotificaciones;
      if (fcmToken != null) datosAActualizar['fcm_token'] = fcmToken;

      final response = await dio.put('/auth/perfil', data: datosAActualizar);
      final datosActualizados =
          response.data['usuario'] as Map<String, dynamic>;
      state = AsyncData(datosActualizados);
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al actualizar los datos');
    }
  }

  // NUEVO: Método para subir foto de perfil
  Future<void> actualizarFotoPerfil(String imagePath) async {
    final dio = ref.read(dioProvider).instance;
    try {
      FormData formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(imagePath, filename: 'perfil.jpg'),
      });
      final response = await dio.put('/auth/perfil/foto', data: formData);
      final nuevaUrl = response.data['foto_perfil'];

      // Actualizamos el estado local agregando la nueva URL
      if (state.hasValue && state.value != null) {
        final currentData = Map<String, dynamic>.from(state.value!);
        currentData['foto_perfil'] = nuevaUrl;
        state = AsyncData(currentData);
      }
    } on DioException catch (e) {
      throw AppException.fromDioException(e);
    } catch (e) {
      throw AppException('Ocurrió un error inesperado al subir la foto');
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>>(() {
      return UserProfileNotifier();
    });
