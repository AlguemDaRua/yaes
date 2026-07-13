import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String uid, XFile imageFile) async {
    try {
      final ref = _storage.ref().child('users/$uid/profile_photo.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        uploadTask = ref.putFile(File(imageFile.path));
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Upload driver documents
  Future<String?> uploadDriverDocument(
    String uid,
    String documentType,
    File imageFile,
  ) async {
    try {
      final ref = _storage.ref().child(
        'drivers/$uid/documents/$documentType.jpg',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(imageFile);
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Delete profile photo
  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref().child('users/$uid/profile_photo.jpg').delete();
    } catch (e) {
      debugPrint('Failed to delete profile photo: $e');
    }
  }

  // Get profile photo URL
  Future<String?> getProfilePhotoUrl(String uid) async {
    try {
      return await _storage
          .ref()
          .child('users/$uid/profile_photo.jpg')
          .getDownloadURL();
    } catch (e) {
      // File doesn't exist or no permission
      return null;
    }
  }
}
