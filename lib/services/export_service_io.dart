import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

class PlatformExport {
  static void downloadFile(String base64Data, String fileName, String mimeType) async {
    try {
      // Decode base64 data
      final bytes = base64Decode(base64Data);
      
      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!directory.existsSync()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Unable to access storage directory');
      }
      
      // Create the file
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      Logger.info('File saved successfully: ${file.path}');
    } catch (e) {
      Logger.error('Failed to save file: $fileName', e);
      rethrow;
    }
  }
}