import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePicture({
    bool fromGallery = false,
    bool cropImage = false,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 70, // Compresión para optimizar red
      );

      if (pickedFile != null && cropImage) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(
            ratioX: 1,
            ratioY: 1,
          ), // Fuerza el cuadrado
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Ajustar Foto',
              toolbarColor: const Color(0xFFD32F2F),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              showCropGrid: true, // Habilita la cuadrícula 3x3
            ),
            IOSUiSettings(
              title: 'Ajustar Foto',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          return XFile(croppedFile.path);
        } else {
          return null; // Si cancela el recorte, evitamos enviar la foto cruda
        }
      }

      return pickedFile;
    } catch (e) {
      throw Exception('Error al procesar la imagen: $e');
    }
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});
