import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePicture({bool fromGallery = false}) async {
    try {
      return await _picker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 70, // Compresión para optimizar red
      );
    } catch (e) {
      throw Exception(
        'Error al abrir la ${fromGallery ? 'galería' : 'cámara'}: $e',
      );
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
