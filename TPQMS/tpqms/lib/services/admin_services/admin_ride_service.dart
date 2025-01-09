// admin_ride_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tpqms/services/common_services/notification_service.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/batch_model.dart';

class AdminRideService {
  final RealtimeDbService _realtimeDb;
  final FirestoreService _firestoreService;
  final RideService _rideService;
  final NotificationService _notificationService;
  static const String _ridesPath = 'rides';
  static const String _adminLogsCollection = 'admin_logs';

  AdminRideService(this._realtimeDb, this._firestoreService, this._rideService,
      this._notificationService);

  Stream<List<BatchModel>> streamCurrentHourBatches(String rideId) {
    print('[ADMIN-SERVICE] Starting batch stream for ride: $rideId');

    final batchPath = '$_ridesPath/$rideId/batches';

    return _realtimeDb.streamData(batchPath).map((event) {
      try {
        if (event.snapshot.value == null) {
          print('[ADMIN-SERVICE] No batches found');
          return [];
        }

        final Map data = event.snapshot.value as Map;
        final now = DateTime.now();

        // Get start of current hour
        final nowUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );

        // Get start of next hour
        final endOfHour = DateTime.utc(
          nowUtc.year,
          nowUtc.month,
          nowUtc.day,
          nowUtc.hour + 1,
        );

        final batches = data.entries.map((entry) {
          return BatchModel.fromMap(entry.key as String,
              Map<String, dynamic>.from(entry.value as Map));
        }).where((batch) {
          final startTime =
              DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
          final endTime =
              DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

          // Only include non-completed batches in current hour
          return endTime.isAfter(nowUtc) &&
              startTime.isBefore(endOfHour) &&
              batch.batchStatus != 'completed';
        }).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        print('[ADMIN-SERVICE] Emitting ${batches.length} batches');
        return batches;
      } catch (e) {
        print('[ADMIN-SERVICE] Error processing batches: $e');
        return [];
      }
    });
  }

  Stream<List<BatchModel>> streamQueueManagementBatches(String rideId) {
    return _realtimeDb.streamData('$_ridesPath/$rideId/batches').map((event) {
      try {
        final Map data = event.snapshot.value as Map;
        final now = DateTime.now();
        final nowUtc = DateTime.utc(
            now.year, now.month, now.day, now.hour, now.minute, now.second);

        // Get all batches and sort them chronologically
        final allBatches = data.entries
            .map((entry) => BatchModel.fromMap(entry.key as String,
                Map<String, dynamic>.from(entry.value as Map)))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        // Find the most recent previous batch
        BatchModel? previousBatch;
        try {
          previousBatch = allBatches.lastWhere((batch) {
            final endTime =
                DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
            return endTime.isBefore(nowUtc);
          });
        } catch (e) {
          // No previous batch found, that's okay
        }

        // Get current and upcoming batches
        final currentAndUpcomingBatches = allBatches.where((batch) {
          final endTime =
              DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
          return endTime.isAfter(nowUtc);
        }).toList();

        // Combine previous batch with current and upcoming batches
        final resultBatches = [
          if (previousBatch != null) previousBatch,
          ...currentAndUpcomingBatches,
        ];

        return resultBatches;
      } catch (e) {
        print('[ADMIN-SERVICE] Error processing batches: $e');
        return [];
      }
    });
  }

  // Add to admin_ride_service.dart
  Future<BatchModel?> getBatch(String rideId, String batchId) async {
    try {
      print('[ADMIN-SERVICE] Getting batch data');
      print('[ADMIN-SERVICE] Ride ID: $rideId, Batch ID: $batchId');

      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      final data = await _realtimeDb.read(batchPath);

      if (data == null) {
        print('[ADMIN-SERVICE] Batch not found');
        return null;
      }

      return BatchModel.fromMap(batchId, Map<String, dynamic>.from(data));
    } catch (e) {
      print('[ADMIN-SERVICE] Error getting batch: $e');
      throw Exception('Failed to get batch: $e');
    }
  }

  // In AdminRideService
  Future<List<BatchModel>> getAvailableBatches(String rideId) async {
    try {
      print('[ADMIN-SERVICE] Getting available batches for ride: $rideId');

      final batchPath = '$_ridesPath/$rideId/batches';
      final data = await _realtimeDb.read(batchPath);

      if (data == null) return [];

      final now = DateTime.now();
      final batches = data.entries.map((entry) {
        return BatchModel.fromMap(
            entry.key, Map<String, dynamic>.from(entry.value as Map));
      }).where((batch) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(batch.startAt);
        final endTime = DateTime.fromMillisecondsSinceEpoch(batch.endAt);
        return endTime.isAfter(now) &&
            batch.completedAt == 0 &&
            batch.batchStatus != 'completed';
      }).toList();

      print('[ADMIN-SERVICE] Found ${batches.length} available batches');
      return batches;
    } catch (e) {
      print('[ADMIN-SERVICE] Error getting available batches: $e');
      throw Exception('Failed to get available batches: $e');
    }
  }

  // Updates a ride's status and logs the action
  Future<void> updateRideStatus({
    required String rideId,
    required String newStatus,
    required String adminId,
  }) async {
    try {
      // If the ride is going under maintenance, handle all batches first
      if (newStatus.toLowerCase() == 'under maintenance') {
        print(
            '[ADMIN-SERVICE] Ride going under maintenance, processing all batches');
        await updateToUnderMaintenance(
          rideId: rideId,
          adminId: adminId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }
      if (newStatus.toLowerCase() == 'closed') {
        print('[ADMIN-SERVICE] Ride is closed, processing all batches');
        await updateToClosed(
          rideId: rideId,
          adminId: adminId,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }

      // Update the ride's status
      final updates = {
        '$_ridesPath/$rideId/status': newStatus,
      };

      await _realtimeDb.runMultiPathTransaction(updates: updates);

      // Log the status change
      await _logAdminAction(
        adminId: adminId,
        rideId: rideId,
        action: 'status_change',
        details: {
          'new_status': newStatus,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('[ADMIN-SERVICE] Error updating ride status: $e');
      throw Exception('Failed to update ride status: $e');
    }
  }

  Future<void> updateToUnderMaintenance({
    required String rideId,
    required String adminId,
    required int timestamp,
  }) async {
    try {
      print('[ADMIN-SERVICE] Starting maintenance process for ride: $rideId');

      // First, get ALL batches for this ride, not just active ones
      final ridePath = '$_ridesPath/$rideId';
      final rideData = await _realtimeDb.read(ridePath);

      if (rideData == null) {
        throw Exception('Ride not found');
      }

      // Get all batches
      final batchesPath = '$ridePath/batches';
      final batchesData = await _realtimeDb.read(batchesPath);

      if (batchesData == null) {
        print('[ADMIN-SERVICE] No batches found for ride');
        return;
      }

      final Map<String, dynamic> updates = {};
      final Set<String> allAffectedVisitors = {};

      // Process each batch
      for (final entry in batchesData.entries) {
        final batchId = entry.key;
        final batchData = Map<String, dynamic>.from(entry.value as Map);

        // Only process batches that haven't been completed yet
        if (batchData['completedAt'] == 0) {
          print('[ADMIN-SERVICE] Processing batch: $batchId');

          // Get visitors in this batch
          final List<String> queueIds =
              List<String>.from(batchData['queueIds'] ?? []);
          queueIds.remove('empty');

          if (queueIds.isNotEmpty) {
            // Add these visitors to our total affected list
            allAffectedVisitors.addAll(queueIds);

            // Update batch status
            updates['$batchesPath/$batchId/completedAt'] = timestamp;
            updates['$batchesPath/$batchId/batchStatus'] = 'failed';
            updates['$batchesPath/$batchId/completedBy'] = adminId;
            updates['$batchesPath/$batchId/queueIds'] = [
              'empty'
            ]; // Reset queue
            updates['$batchesPath/$batchId/maintenanceTimestamp'] = timestamp;

            // Remove queue status for each visitor
            for (final visitorId in queueIds) {
              updates['queueStatus/$visitorId/$rideId'] = null;
            }
          }
        }
      }

      // Execute all updates in a single transaction
      if (updates.isNotEmpty) {
        print(
            '[ADMIN-SERVICE] Executing updates for ${allAffectedVisitors.length} total affected visitors');
        await _realtimeDb.runMultiPathTransaction(updates: updates);

        // Update tickets for all affected visitors
        for (final visitorId in allAffectedVisitors) {
          final queryFilters = [QueryFilter('userId', visitorId)];
          final ticketsSnapshot = await _firestoreService.queryDocuments(
            'tickets',
            queryFilters,
          );

          // Decrement rides queued for each visitor's ticket
          for (final doc in ticketsSnapshot.docs) {
            await _firestoreService.updateDocument('tickets', doc.id, {
              'ridesQueued': FieldValue.increment(-1),
            });
          }
        }

        // Handle notifications
        final rideModel = await _rideService.getRideById(rideId);
        if (rideModel != null) {
          // Cancel all existing notifications for this ride
          final batches = await _rideService.getBatches(rideId);
          for (final batch in batches) {
            await _notificationService.cancelRideNotification(batch);
          }

          // Send maintenance notification to all affected visitors
          await _notificationService.sendMaintenanceNotification(
            rideModel,
            affectedVisitors: allAffectedVisitors.toList(),
          );
        }

        // Log the maintenance action
        await _logAdminAction(
          adminId: adminId,
          rideId: rideId,
          action: 'maintenance_ride_closure',
          details: {
            'maintenance_time': timestamp,
            'total_affected_visitors': allAffectedVisitors.length,
            'maintenance_time_utc':
                DateTime.fromMillisecondsSinceEpoch(timestamp)
                    .toUtc()
                    .toString(),
          },
        );
      }

      print(
          '[ADMIN-SERVICE] Successfully processed maintenance updates for ride $rideId');
    } catch (e) {
      print('[ADMIN-SERVICE] Error processing maintenance updates: $e');
      throw Exception('Failed to process maintenance updates: $e');
    }
  }

  // Updates a ride to 'closed' status and handles all affected visitors
  Future<void> updateToClosed({
    required String rideId,
    required String adminId,
    required int timestamp,
  }) async {
    try {
      print('[ADMIN-SERVICE] Starting closure process for ride: $rideId');

      // First, get ride data to verify it exists
      final ridePath = '$_ridesPath/$rideId';
      final rideData = await _realtimeDb.read(ridePath);

      if (rideData == null) {
        throw Exception('Ride not found');
      }

      // Get all batches
      final batchesPath = '$ridePath/batches';
      final batchesData = await _realtimeDb.read(batchesPath);

      if (batchesData == null) {
        print('[ADMIN-SERVICE] No batches found for ride');
        return;
      }

      final Map<String, dynamic> updates = {};
      final Set<String> allAffectedVisitors = {};

      // Process each batch
      for (final entry in batchesData.entries) {
        final batchId = entry.key;
        final batchData = Map<String, dynamic>.from(entry.value as Map);

        // Only process batches that haven't been completed yet
        if (batchData['completedAt'] == 0) {
          print('[ADMIN-SERVICE] Processing batch: $batchId');

          // Get visitors in this batch
          final List<String> queueIds =
              List<String>.from(batchData['queueIds'] ?? []);
          queueIds.remove('empty');

          if (queueIds.isNotEmpty) {
            // Add these visitors to our total affected list
            allAffectedVisitors.addAll(queueIds);

            // Update batch status and remove all visitors
            updates['$batchesPath/$batchId/completedAt'] = timestamp;
            updates['$batchesPath/$batchId/batchStatus'] = 'failed';
            updates['$batchesPath/$batchId/completedBy'] = adminId;
            updates['$batchesPath/$batchId/queueIds'] = [
              'empty'
            ]; // Reset queue
            updates['$batchesPath/$batchId/closureTimestamp'] = timestamp;

            // Remove queue status for each visitor
            for (final visitorId in queueIds) {
              updates['queueStatus/$visitorId/$rideId'] = null;
            }
          }
        }
      }

      // Execute all updates in a single transaction
      if (updates.isNotEmpty) {
        print(
            '[ADMIN-SERVICE] Executing updates for ${allAffectedVisitors.length} total affected visitors');
        await _realtimeDb.runMultiPathTransaction(updates: updates);

        // Update tickets for all affected visitors
        for (final visitorId in allAffectedVisitors) {
          final queryFilters = [QueryFilter('userId', visitorId)];
          final ticketsSnapshot = await _firestoreService.queryDocuments(
            'tickets',
            queryFilters,
          );

          // Decrement rides queued for each visitor's ticket
          for (final doc in ticketsSnapshot.docs) {
            await _firestoreService.updateDocument('tickets', doc.id, {
              'ridesQueued': FieldValue.increment(-1),
            });
          }
        }

        // Handle notifications
        final rideModel = await _rideService.getRideById(rideId);
        if (rideModel != null) {
          // Cancel all existing notifications for this ride
          final batches = await _rideService.getBatches(rideId);
          for (final batch in batches) {
            await _notificationService.cancelRideNotification(batch);
          }

          // Send closure notification to all affected visitors
          await _notificationService.sendClosedNotification(
            rideModel,
            affectedVisitors: allAffectedVisitors.toList(),
          );
        }

        // Log the closure action
        await _logAdminAction(
          adminId: adminId,
          rideId: rideId,
          action: 'ride_closure',
          details: {
            'closure_time': timestamp,
            'total_affected_visitors': allAffectedVisitors.length,
            'closure_time_utc': DateTime.fromMillisecondsSinceEpoch(timestamp)
                .toUtc()
                .toString(),
          },
        );
      }

      print(
          '[ADMIN-SERVICE] Successfully processed closure updates for ride $rideId');
    } catch (e) {
      print('[ADMIN-SERVICE] Error processing closure updates: $e');
      throw Exception('Failed to process closure updates: $e');
    }
  }

  // Completes a batch and updates necessary records
  Future<void> completeBatch({
    required String rideId,
    required String batchId,
    required String adminId,
    required int timestamp,
  }) async {
    try {
      print('\n[ADMIN-SERVICE] Starting batch completion process');

      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      final batchData = await _realtimeDb.read(batchPath);

      if (batchData == null) {
        throw Exception('Batch not found');
      }

      final List<String> queueIds =
          List<String>.from(batchData['queueIds'] ?? []);
      queueIds.remove('empty');

      int totalBatchWaitTime = 0;
      int processedUsers = 0;
      final now = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final malaysiaOffset = Duration(hours: 8);
      final adjustedTimestamp = now.add(malaysiaOffset).millisecondsSinceEpoch;

      // Get queue status for each user to calculate wait times
      for (final userId in queueIds) {
        final queueStatusPath = 'queueStatus/$userId/$rideId';
        final queueStatus = await _realtimeDb.read(queueStatusPath);

        if (queueStatus != null && queueStatus['joinQueueTime'] != null) {
          final joinTime = queueStatus['joinQueueTime'] as int;
          print('[ADMIN-SERVICE] join time: ${joinTime}');

          // Calculate wait time from join time to completion
          if (adjustedTimestamp > joinTime) {
            final waitTime = adjustedTimestamp - joinTime;
            totalBatchWaitTime += waitTime;
            processedUsers++;

            // Add detailed logging
            print('[ADMIN-SERVICE] Wait time calculation for user $userId:');
            print(
                '  Join time: ${DateTime.fromMillisecondsSinceEpoch(joinTime)}');
            print('  Wait duration: ${waitTime / 1000 / 60} minutes');
          }
        }
      }

      print('[ADMIN-SERVICE] Timestamp conversions:');
      print('  Original completion time: ${now}');
      print(
          '  Adjusted completion time: ${DateTime.fromMillisecondsSinceEpoch(adjustedTimestamp)}');

      // Calculate average wait time for the batch
      final averageWaitTime =
          processedUsers > 0 ? totalBatchWaitTime ~/ processedUsers : 0;

      print('[ADMIN-SERVICE] Batch timing details:');
      print(
          '  Start time: ${DateTime.fromMillisecondsSinceEpoch(batchData['startAt'] as int)}');
      print(
          '  End time: ${DateTime.fromMillisecondsSinceEpoch(batchData['endAt'] as int)}');
      print(
          '  Completion time: ${DateTime.fromMillisecondsSinceEpoch(adjustedTimestamp)}');
      print('  Average wait time: ${averageWaitTime / 1000 / 60} minutes');

      // Prepare updates with additional wait time information
      final Map<String, dynamic> updates = {
        '$batchPath/completedAt': adjustedTimestamp,
        '$batchPath/batchStatus': 'completed',
        '$batchPath/completedBy': adminId,
        '$batchPath/averageWaitTime':
            averageWaitTime, // Add average wait time to batch
      };

      // Remove queue status entries for each user
      for (final userId in queueIds) {
        updates['queueStatus/$userId/$rideId'] = null;

        // Update ticket count
        final queryFilters = [QueryFilter('userId', userId)];
        final ticketsSnapshot = await _firestoreService.queryDocuments(
          'tickets',
          queryFilters,
        );

        for (final doc in ticketsSnapshot.docs) {
          await _firestoreService.updateDocument('tickets', doc.id, {
            'ridesQueued': FieldValue.increment(-1),
          });
        }
      }

      // Execute updates
      await _realtimeDb.runMultiPathTransaction(updates: updates);
      final batch = await _rideService.getBatchById(rideId, batchId);

      await _notificationService.cancelRideNotification(batch);
      // Log admin action with wait time information
      await _logAdminAction(
        adminId: adminId,
        rideId: rideId,
        action: 'complete_batch',
        details: {
          'batch_id': batchId,
          'completion_time': timestamp,
          'users_processed': queueIds.length,
          'average_wait_time': averageWaitTime,
          'completion_time_utc':
              DateTime.fromMillisecondsSinceEpoch(timestamp).toUtc().toString(),
        },
      );

      print('[ADMIN-SERVICE] Batch completion successful');
    } catch (e) {
      print('[ADMIN-SERVICE] Error completing batch: $e');
      throw Exception('Failed to complete batch: $e');
    }
  }

  // Removes a visitor from queue with admin override
  Future<void> adminDequeueVisitor({
    required String rideId,
    required String batchId,
    required String visitorId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      final batchData = await _realtimeDb.read(batchPath);
      final queueStatusPath = 'queueStatus/$visitorId/$rideId';

      if (batchData == null) {
        throw Exception('Batch not found');
      }

      // Get current queue IDs and remove the visitor
      List<dynamic> queueIds = List.from(batchData['queueIds'] ?? []);
      queueIds.remove(visitorId);

      // If queue becomes empty, add 'empty' placeholder
      if (queueIds.isEmpty) {
        queueIds.add('empty');
      }

      // Update the queue
      final updates = {
        '$batchPath/queueIds': queueIds,
        // Reset queueFilledAt if queue is no longer full
        '$batchPath/queueFilledAt': 'Not Filled Up',
        queueStatusPath: null,
      };

      await _realtimeDb.runMultiPathTransaction(updates: updates);
      // Query Firestore for tickets with matching userId
      final queryFilters = [QueryFilter('userId', visitorId)];
      final ticketsSnapshot = await _firestoreService.queryDocuments(
        'tickets',
        queryFilters,
      );

      // Decrement ridesQueued for all matching tickets
      for (final doc in ticketsSnapshot.docs) {
        await _firestoreService.updateDocument('tickets', doc.id, {
          'ridesQueued': FieldValue.increment(-1),
        });
      }
      final batch = await _rideService.getBatchById(rideId, batchId);

      await _notificationService.cancelRideNotification(batch);
      final rideModel = await _rideService.getRideById(rideId);
      final batchModel = await _rideService.getBatchById(rideId, batchId);
      if (rideModel != null && batchModel != null) {
        await _notificationService.sendDequeueNotification(
          rideModel,
          batchModel,
        );
        print('[ADMIN-SERVICE] Dequeue notification sent successfully');
      }
      // Log the dequeue action
      await _logAdminAction(
        adminId: adminId,
        rideId: rideId,
        action: 'admin_dequeue',
        details: {
          'visitor_id': visitorId,
          'batch_id': batchId,
          'reason': reason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      throw Exception('Failed to dequeue visitor: $e');
    }
  }

  Future<void> markVisitorAsMissedQueue({
    required String rideId,
    required String batchId,
    required String visitorId,
    required String adminId,
    required String reason,
  }) async {
    try {
      // Similar to dequeueVisitor but with missedQueue increment
      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      final batchData = await _realtimeDb.read(batchPath);
      final queueStatusPath = 'queueStatus/$visitorId/$rideId';

      if (batchData == null) {
        throw Exception('Batch not found');
      }

      // Get current queue IDs and remove the visitor
      List<dynamic> queueIds = List.from(batchData['queueIds'] ?? []);
      queueIds.remove(visitorId);

      if (queueIds.isEmpty) {
        queueIds.add('empty');
      }

      // Update the queue
      final updates = {
        '$batchPath/queueIds': queueIds,
        '$batchPath/queueFilledAt': 'Not Filled Up',
        queueStatusPath: null,
      };

      await _realtimeDb.runMultiPathTransaction(updates: updates);

      // Get visitor's ticket and increment missedQueue
      final queryFilters = [QueryFilter('userId', visitorId)];
      final ticketsSnapshot = await _firestoreService.queryDocuments(
        'tickets',
        queryFilters,
      );

      // Update ticket counts for all matching tickets
      for (final doc in ticketsSnapshot.docs) {
        await _firestoreService.updateDocument('tickets', doc.id, {
          'ridesQueued': FieldValue.increment(-1),
          'missedQueue':
              FieldValue.increment(1), // Increment missed queue count
        });
      }

      // Handle notifications
      final batch = await _rideService.getBatchById(rideId, batchId);
      await _notificationService.cancelRideNotification(batch);

      final rideModel = await _rideService.getRideById(rideId);
      final batchModel = await _rideService.getBatchById(rideId, batchId);

      if (rideModel != null && batchModel != null) {
        await _notificationService.sendMissedQueueNotification(
          rideModel,
          batchModel,
        );
      }

      // Log the action
      await _logAdminAction(
        adminId: adminId,
        rideId: rideId,
        action: 'mark_missed_queue',
        details: {
          'visitor_id': visitorId,
          'batch_id': batchId,
          'reason': reason,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      throw Exception('Failed to mark visitor as missed queue: $e');
    }
  }

  // Logs admin actions for accountability
  Future<void> _logAdminAction({
    required String adminId,
    required String rideId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      final logEntry = {
        'adminId': adminId,
        'rideId': rideId,
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'details': details,
      };

      await _firestoreService.addDocument(
        _adminLogsCollection,
        null, // Let Firestore generate the ID
        logEntry,
      );
    } catch (e) {
      print('Failed to log admin action: $e');
      // Don't throw here - logging failure shouldn't stop the main operation
    }
  }

  // Gets the action log for a specific ride
  Stream<List<Map<String, dynamic>>> getRideActionLog(String rideId) {
    return _firestoreService.getDocuments(_adminLogsCollection,
        filters: [QueryFilter('rideId', rideId)]).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Gets all actions by a specific admin
  Stream<List<Map<String, dynamic>>> getAdminActionLog(String adminId) {
    return _firestoreService.getDocuments(_adminLogsCollection,
        filters: [QueryFilter('adminId', adminId)]).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }
}
