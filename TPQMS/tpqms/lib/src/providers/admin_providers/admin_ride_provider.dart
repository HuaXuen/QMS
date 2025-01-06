// admin_ride_provider.dart

import 'package:flutter/material.dart';
import 'package:tpqms/services/admin_services/admin_ride_service.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/src/model/admin_model/admin_model.dart';
import 'package:tpqms/src/model/batch_model.dart';

class AdminRideProvider extends ChangeNotifier {
  final AdminRideService _adminRideService;
  bool _isLoading = false;
  String? _error;
  bool _isTestMode = false; // Add test mode flag
  DateTime get currentTime => _isTestMode
      ? DateTime(2025, 1, 1, 14, 0) // Test time
      : DateTime.now();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminRideProvider(this._adminRideService);

  Stream<List<BatchModel>> streamCurrentHourBatches(String rideId) {
    return _adminRideService.streamCurrentHourBatches(rideId);
  }

  // Updates a ride's status
  Future<void> updateRideStatus({
    required String rideId,
    required String newStatus,
    required String adminId,
  }) async {
    _setLoading(true);
    try {
      await _adminRideService.updateRideStatus(
        rideId: rideId,
        newStatus: newStatus,
        adminId: adminId,
      );
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Completes a batch
  // Enhanced complete batch with detailed logging
  Future<void> completeBatch({
    required String rideId,
    required String batchId,
    required String adminId,
  }) async {
    try {
      final now = currentTime;
      print('\n[COMPLETE-BATCH] Starting batch completion');
      print('[COMPLETE-BATCH] Ride ID: $rideId');
      print('[COMPLETE-BATCH] Batch ID: $batchId');
      print('[COMPLETE-BATCH] Admin ID: $adminId');
      print('[COMPLETE-BATCH] Timestamp (Local): ${now.toLocal()}');
      print('[COMPLETE-BATCH] Timestamp (UTC): ${now.toUtc()}');

      await _adminRideService.completeBatch(
        rideId: rideId,
        batchId: batchId,
        adminId: adminId,
        timestamp: now.millisecondsSinceEpoch,
      );

      print('[COMPLETE-BATCH] Successfully completed');
    } catch (e) {
      print('[COMPLETE-BATCH] Failed: $e');
      rethrow;
    }
  }

  // Dequeues a visitor with admin override
  Future<void> dequeueVisitor({
    required String rideId,
    required String batchId,
    required String visitorId,
    required String adminId,
    required String reason,
  }) async {
    try {
      print('\n[MANAGE-QUEUE] Starting visitor dequeue:');
      print('[MANAGE-QUEUE] Ride ID: $rideId');
      print('[MANAGE-QUEUE] Batch ID: $batchId');
      print('[MANAGE-QUEUE] Visitor ID: $visitorId');
      print('[MANAGE-QUEUE] Admin ID: $adminId');
      print('[MANAGE-QUEUE] Reason: $reason');
      print('[MANAGE-QUEUE] Time: ${currentTime.toIso8601String()}');

      await _adminRideService.adminDequeueVisitor(
        rideId: rideId,
        batchId: batchId,
        visitorId: visitorId,
        adminId: adminId,
        reason: reason,
      );

      print('[MANAGE-QUEUE] Visitor dequeued successfully');
    } catch (e) {
      print('[MANAGE-QUEUE] Error: $e');
      rethrow;
    }
  }

  // Gets action log for a ride
  Stream<List<AdminAction>> getRideActionLog(String rideId) {
    return _adminRideService.getRideActionLog(rideId).map((actions) {
      return actions.map((action) {
        return AdminAction.fromMap(action['id'], action);
      }).toList();
    });
  }

  // Gets all actions by an admin
  Stream<List<AdminAction>> getAdminActionLog(String adminId) {
    return _adminRideService.getAdminActionLog(adminId).map((actions) {
      return actions.map((action) {
        return AdminAction.fromMap(action['id'], action);
      }).toList();
    });
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
