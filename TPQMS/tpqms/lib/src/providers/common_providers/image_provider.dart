import 'package:flutter/material.dart';
import 'package:tpqms/services/firebase_services/storage_service.dart';

class ImageProviderService with ChangeNotifier {
  final StorageService _storageService = StorageService();

  String? _imageUrl;
  String? get imageUrl => _imageUrl;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Method to load image URL from Firebase Storage
  Future<void> loadImage(String folderPath, String imagePath) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Construct the full path for the image in Firebase Storage
      String fullPath = '$folderPath/$imagePath';
      _imageUrl = await _storageService.getImageUrl(fullPath);
    } catch (e) {
      _imageUrl = null; // Clear image URL on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
