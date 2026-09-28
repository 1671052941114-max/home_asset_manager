import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  ImageService._();

  static final ImageService instance = ImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (image == null) {
      return null;
    }

    return _saveImage(image);
  }

  Future<String?> takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image == null) {
      return null;
    }

    return _saveImage(image);
  }

  Future<String?> _saveImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();

    final imageDirectory = Directory(
      '${directory.path}/asset_images',
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(
        recursive: true,
      );
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extension = _getExtension(image.path);

    final fileName = 'asset_$timestamp$extension';

    final destination = File(
      '${imageDirectory.path}/$fileName',
    );

    await image.saveTo(destination.path);

    if (!await destination.exists()) {
      return null;
    }

    final fileLength = await destination.length();

    if (fileLength == 0) {
      return null;
    }

    return destination.path;
  }

  String _getExtension(String path) {
    final lowerPath = path.toLowerCase();

    if (lowerPath.endsWith('.png')) {
      return '.png';
    }

    if (lowerPath.endsWith('.webp')) {
      return '.webp';
    }

    if (lowerPath.endsWith('.heic')) {
      return '.heic';
    }

    if (lowerPath.endsWith('.jpeg')) {
      return '.jpeg';
    }

    return '.jpg';
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}