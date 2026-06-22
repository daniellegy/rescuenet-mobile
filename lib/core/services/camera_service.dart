import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePicture() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
    } catch (e) {
      throw Exception('Error al abrir la cámara: $e');
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
