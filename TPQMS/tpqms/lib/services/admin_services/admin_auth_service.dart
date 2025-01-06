// admin_auth_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/admin_model/admin_model.dart';

// admin_auth_service.dart
class AdminAuthService {
  final FirestoreService _firestoreService;

  AdminAuthService(this._firestoreService);

  Future<AdminModel?> login(String employeeCode, String password) async {
    try {
      final querySnapshot = await _firestoreService.queryDocuments(
        'admin',
        [QueryFilter('employee_code', employeeCode)],
      );

      if (querySnapshot.docs.isEmpty) {
        throw AdminAuthError('not_found', 'Admin not found');
      }

      final adminDoc = querySnapshot.docs.first;
      final adminData = adminDoc.data() as Map<String, dynamic>;

      if (adminData['password'] != password) {
        throw AdminAuthError('invalid_password', 'Invalid password');
      }

      if (!(adminData['status'] ?? false)) {
        throw AdminAuthError('account_disabled', 'Admin account is disabled');
      }

      return AdminModel.fromMap(adminDoc.id, adminData);
    } catch (e) {
      print('Login error: $e');
      rethrow; // Propagate the error instead of returning null
    }
  }

  Future<void> logout() async {
    // Clear stored admin session
    final prefs = await SharedPreferences.getInstance();
    //await prefs.remove('admin_session');
    await prefs.clear();
  }
}

class AdminAuthError {
  final String message;
  final String code;

  AdminAuthError(this.code, this.message);
}
