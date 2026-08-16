import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file for a user scan (images, video, audio)
  /// Returns the download URL string
  static Future<String?> uploadUserScanMedia({
    required String userId,
    required String fileName,
    required dynamic fileData, // File on mobile/desktop, Uint8List on web
  }) async {
    try {
      final ref = _storage.ref().child("user_scans/$userId/$fileName");
      UploadTask task;

      if (kIsWeb) {
        if (fileData is Uint8List) {
          task = ref.putData(fileData);
        } else {
          throw ArgumentError("On web, fileData must be Uint8List");
        }
      } else {
        if (fileData is File) {
          task = ref.putFile(fileData);
        } else if (fileData is Uint8List) {
          task = ref.putData(fileData);
        } else {
          throw ArgumentError("Invalid file data type");
        }
      }

      final snapshot = await task;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("FirebaseStorageService uploadUserScanMedia error: $e");
      return null;
    }
  }

  /// Upload a generated PDF audit report or certificate
  static Future<String?> uploadReportPdf({
    required String certId,
    required String fileName,
    required Uint8List pdfBytes,
  }) async {
    try {
      final ref = _storage.ref().child("reports/$certId/$fileName");
      final task = ref.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("FirebaseStorageService uploadReportPdf error: $e");
      return null;
    }
  }

  /// Get download URL for a given path
  static Future<String?> getDownloadUrl(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } catch (e) {
      debugPrint("FirebaseStorageService getDownloadUrl error: $e");
      return null;
    }
  }
}
