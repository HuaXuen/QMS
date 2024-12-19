import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to get the download URL of an image from Firebase Storage
  Future<String> getImageUrl(String path) async {
    try {
      String downloadUrl = await _storage.ref(path).getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to get image URL: $e');
    }
  }
}
