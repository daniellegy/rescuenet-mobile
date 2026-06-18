import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  
  @override
  Future<Map<String, dynamic>> build() async {

    final dio = ref.read(dioProvider).instance;

    try {
      final response = await dio.get('/auth/perfil');

      if (response.statusCode == 200) {
        // CAMBIO PRINCIPAL 4: RETORNO DIRECTO DEL MAPA DE DATOS
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('No se pudo obtener el perfil del servidor');
      }
    } catch (e) {
      throw Exception('Error de red al conectar con el backend: $e');
    }
  }

  Future<void> actualizarCampo({String? telefono, int? role}) async {
    final dio = ref.read(dioProvider).instance;
    
    try {
      final Map<String, dynamic> datosAActualizar = {};
      if (telefono != null) datosAActualizar['telefono'] = telefono;
      if (role != null) datosAActualizar['role'] = role;

      final response = await dio.put('/auth/perfil', data: datosAActualizar);
      if (response.statusCode == 200) {
        final datosActualizados = response.data['usuario'] as Map<String, dynamic>;
        
        state = AsyncData(datosActualizados);
      } else {
        throw Exception('El servidor rechazó la actualización del perfil');
      }
    } catch (e) {
      throw Exception('Error al actualizar los datos en el backend: $e');
    }
  }
}

final userProfileProvider = AsyncNotifierProvider.autoDispose<UserProfileNotifier, Map<String, dynamic>>(() {
  return UserProfileNotifier();
});