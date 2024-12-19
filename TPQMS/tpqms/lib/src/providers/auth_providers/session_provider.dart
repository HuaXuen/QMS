import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class SessionManagerProvider with ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys for storing session data
  static const String _sessionTokenKey = 'session_token';
  static const String _timestampKey = 'session_timestamp';

  // Save session token and timestamp
  Future<void> saveSession(String token) async {
    final DateTime currentTime = DateTime.now();
    await _secureStorage.write(key: _sessionTokenKey, value: token);
    await _secureStorage.write(
        key: _timestampKey, value: currentTime.toIso8601String());
    notifyListeners(); // Notify listeners if session data affects the UI
  }

  // Retrieve the session token
  Future<String?> getSessionToken() async {
    return await _secureStorage.read(key: _sessionTokenKey);
  }

  // Check if the session is still valid
  Future<bool> isSessionValid() async {
    final String? timestampString =
        await _secureStorage.read(key: _timestampKey);
    if (timestampString == null) return false;

    final DateTime timestamp = DateTime.parse(timestampString);
    final Duration elapsed = DateTime.now().difference(timestamp);

    // Session expires after 1 hour
    return elapsed.inMinutes < 60;
  }

  // Clear session data
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionTokenKey);
    await _secureStorage.delete(key: _timestampKey);
    notifyListeners();
  }
}
