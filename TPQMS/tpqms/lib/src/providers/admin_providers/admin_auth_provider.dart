// admin_auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpqms/common/admin_constants/admin_session_constants.dart';
import 'package:tpqms/services/admin_services/admin_auth_service.dart';
import 'package:tpqms/src/model/admin_model/admin_model.dart';

class AdminAuthProvider extends ChangeNotifier {
  // Dependencies are injected through constructor
  final AdminAuthService _authService;

  // State management
  AdminModel? _currentAdmin;
  bool _isLoading = false;
  Timer? _sessionTimer;
  Timer? _inactivityTimer;

  // Constructor with required dependency
  AdminAuthProvider(this._authService) {
    // Check for existing session on initialization
    _checkExistingSession();
  }

  // Getters for state
  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;

  // Check if there's an existing valid session
  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(AdminSessionConstants.sessionKey);

    if (sessionJson != null) {
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(sessionData['expiresAt'] as int);

      if (DateTime.now().isBefore(expiresAt)) {
        // Session is still valid
        final adminData = sessionData['admin'] as Map<String, dynamic>;
        _currentAdmin = AdminModel.fromMap(adminData['adminId'], adminData);
        _startSessionTimers();
        notifyListeners();
      } else {
        // Session expired, clean up
        await logout();
      }
    }
  }

  // Login implementation
  Future<bool> login(String employeeCode, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final admin = await _authService.login(employeeCode, password);
      _currentAdmin = admin;
      await _saveSession(admin!);
      _startSessionTimers();
      return true;
    } on AdminAuthError catch (e) {
      print('Auth error: ${e.message}');
      rethrow; // Propagate the specific error
    } catch (e) {
      print('Unexpected error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save session data to SharedPreferences
  Future<void> _saveSession(AdminModel admin) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = {
      'admin': admin.toMap(),
      'expiresAt': DateTime.now()
          .add(AdminSessionConstants.sessionDuration)
          .millisecondsSinceEpoch,
    };
    await prefs.setString(
        AdminSessionConstants.sessionKey, jsonEncode(sessionData));
  }

  // Logout implementation
  Future<void> logout() async {
    try {
      // Clear timers
      _sessionTimer?.cancel();
      _inactivityTimer?.cancel();

      // Clear session data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AdminSessionConstants.sessionKey);

      // Clear state
      _currentAdmin = null;

      // Notify service
      await _authService.logout();

      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      // Even if logout fails, we should clear local state
      _currentAdmin = null;
      notifyListeners();
    }
  }

  // Session timer management
  void _startSessionTimers() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      AdminSessionConstants.sessionDuration,
      () {
        logout();
        // You can use a global navigation key or context to show session expired dialog
        // We'll implement this in the UI layer
      },
    );
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      AdminSessionConstants.inactivityTimeout,
      logout,
    );
  }

  // Activity tracking
  void registerActivity() {
    _resetInactivityTimer();
  }

  // Clean up resources
  @override
  void dispose() {
    _sessionTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
