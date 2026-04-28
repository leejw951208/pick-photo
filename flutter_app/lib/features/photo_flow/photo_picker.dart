import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'photo_flow_api.dart';

abstract class PhotoPicker {
  Future<LocalPhotoFile?> pickPhoto();
}

class FilePickerPhotoPicker implements PhotoPicker {
  @override
  Future<LocalPhotoFile?> pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;

    if (file == null || bytes == null) {
      return null;
    }

    return LocalPhotoFile(
      name: file.name,
      bytes: Uint8List.fromList(bytes),
      contentType: _contentTypeForExtension(file.extension),
    );
  }

  String _contentTypeForExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }
}
