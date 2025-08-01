import 'dart:io';
import 'package:househelp/config/supabase_config.dart';
import 'package:image_picker/image_picker.dart';

class FileStorageService {
  static final _storage = SupabaseConfig.client.storage;

  /// Upload a file to Supabase Storage and return the download URL
  static Future<String> uploadFile(XFile file, String folder) async {
    try {
      // Create a unique filename
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String filePath = '$folder/$fileName';

      // Read file bytes
      final bytes = await File(file.path).readAsBytes();

      // Upload to Supabase Storage
      await _storage.from('files').uploadBinary(filePath, bytes);

      // Get download URL
      final String downloadUrl = _storage.from('files').getPublicUrl(filePath);

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload a file specifically for chat attachments
  static Future<String> uploadChatAttachment(
      XFile file, String chatId, String senderId) async {
    final String folder = 'chat_attachments/$chatId/$senderId';
    return await uploadFile(file, folder);
  }

  /// Get file type from extension
  static String getFileType(String fileName) {
    final String extension = fileName.toLowerCase().split('.').last;

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']
        .contains(extension)) {
      return 'video';
    } else if (['pdf'].contains(extension)) {
      return 'pdf';
    } else if (['doc', 'docx'].contains(extension)) {
      return 'document';
    } else {
      return 'file';
    }
  }

  /// Delete a file from Supabase Storage
  static Future<void> deleteFile(String filePath) async {
    try {
      await _storage.from('files').remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get file size in a readable format
  static String getReadableFileSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const List<String> suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
