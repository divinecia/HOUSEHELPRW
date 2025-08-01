import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FileStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage and return the download URL
  static Future<String> uploadFile(XFile file, String folder) async {
    try {
      // Create a unique filename
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final String filePath = '$folder/$fileName';

      // Create a reference to Firebase Storage
      final Reference ref = _storage.ref().child(filePath);

      // Upload the file
      final UploadTask uploadTask = ref.putFile(File(file.path));

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

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
    final String extension = path.extension(fileName).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        .contains(extension)) {
      return 'image';
    } else if (['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm']
        .contains(extension)) {
      return 'video';
    } else if (['.pdf'].contains(extension)) {
      return 'pdf';
    } else if (['.doc', '.docx'].contains(extension)) {
      return 'document';
    } else {
      return 'file';
    }
  }

  /// Delete a file from Firebase Storage
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
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
