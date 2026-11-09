import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../utils/logger.dart';

class ProfileImagePicker {
  static Future<Uint8List?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        Logger.debug(
          'Image selected: ${image.name}, size: ${await image.length()}',
        );
        return await image.readAsBytes();
      }

      return null;
    } catch (e) {
      Logger.error('Error picking image on mobile/desktop', e);
      return null;
    }
  }
}
