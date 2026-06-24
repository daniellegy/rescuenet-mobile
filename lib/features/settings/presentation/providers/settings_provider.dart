import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final authState = ref.watch(authProvider);

    if (!authState.isLogged) {
      return {};
    }

    final dio = ref.read(dioProvider).instance;

    try {
      final response = await dio.get('/auth/perfil');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('No se pudo obtener el perfil del servidor');
      }
    } catch (e) {
      throw Exception('Error de red al conectar con el backend: $e');
    }
  }

  // AÑADIDO: Parámetro curp
  Future<void> actualizarCampo({
    String? telefono,
    String? email,
    int? role,
    String? curp,
  }) async {
    final dio = ref.read(dioProvider).instance;

    try {
      final Map<String, dynamic> datosAActualizar = {};
      if (telefono != null) datosAActualizar['telefono'] = telefono;
      if (email != null) datosAActualizar['email'] = email;
      if (role != null) datosAActualizar['role'] = role;
      if (curp != null) datosAActualizar['curp'] = curp;

      final response = await dio.put('/auth/perfil', data: datosAActualizar);
      if (response.statusCode == 200) {
        final datosActualizados =
            response.data['usuario'] as Map<String, dynamic>;
        state = AsyncData(datosActualizados);
      } else {
        throw Exception('El servidor rechazó la actualización del perfil');
      }
    } catch (e) {
      throw Exception('Error al actualizar los datos: $e');
    }
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>>(() {
      return UserProfileNotifier();
    });
