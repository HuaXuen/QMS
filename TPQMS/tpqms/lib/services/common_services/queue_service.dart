// queue_service.dart
import 'package:intl/intl.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/src/model/queue_model.dart';
import 'package:tpqms/src/model/ride_model.dart';

class QueueService {
  final RealtimeDbService _dbService;
  final RideService _rideService;
  static const String _queueStatusPath = 'queueStatus';
  static const String _ridesPath = 'rides';
  final bool _isTestMode = false;

  QueueService(this._dbService, this._rideService) {
    print('[QUEUE] Initializing QueueService');
  }

  /// Adds a user to a ride's batch queue and creates a queue status entry.
  /// Uses a transaction to ensure both operations succeed or fail together.
  Future<Map<String, dynamic>> enqueueVisitor({
    required String userId,
    required String rideId,
    required String batchId,
    required int startAt,
    required int endAt,
  }) async {
    print('[QUEUE] Starting enqueueVisitor operation');
    print(
        '[QUEUE] Parameters - userId: $userId, rideId: $rideId, batchId: $batchId');
    print(
        '[QUEUE] Queue time - start: ${DateTime.fromMillisecondsSinceEpoch(startAt)}, end: ${DateTime.fromMillisecondsSinceEpoch(endAt)}');

    try {
      // First, read the current batch data to check if queue is possible
      final ridePath = '$_ridesPath/$rideId';
      final rideSnapshot = await _dbService.read(ridePath);
      if (rideSnapshot == null) {
        throw Exception('Ride not found');
      }
      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      print('[QUEUE] Fetching batch data from path: $batchPath');

      final batchData = await _dbService.read(batchPath);
      print('[QUEUE] Retrieved batch data: $batchData');

      if (batchData == null) {
        print('[QUEUE] ERROR: Batch not found at path: $batchPath');
        return {'success': false, 'message': 'Batch not found'};
      }
      // Validate timestamp data
      if (batchData['startAt'] == null || batchData['endAt'] == null) {
        throw Exception('Invalid batch data: missing timestamps');
      }
      final conflictCheck = await _checkTimeConflicts(
        userId: userId,
        newStartAt: startAt,
        newEndAt: endAt,
      );

      if (conflictCheck['hasConflict']) {
        return {
          'success': false,
          'message':
              'Time conflict detected: You are already queued for ${conflictCheck['conflictingRide']} during ${conflictCheck['conflictTime']}, please select another timeslot.'
        };
      }

      RideModel? rideModel = await _rideService.getRideById(rideId);
      String rideName = rideModel!.name;

      // Prepare queueIds update
      List<dynamic> queueIds = List.from(batchData['queueIds'] ?? ['empty']);
      print('[QUEUE] Current queue IDs: $queueIds');

      if (queueIds.contains('empty')) {
        queueIds.remove('empty');
        print('[QUEUE] Removed placeholder "empty" value from queueIds');
      }

      if (queueIds.contains(userId)) {
        print('[QUEUE] ERROR: User $userId is already in queue');
        return {'success': false, 'message': 'Already in queue'};
      }

      queueIds.add(userId);
      print('[QUEUE] Added userId to queue. New queue IDs: $queueIds');

      final now = _isTestMode ? DateTime(2025, 1, 1, 14, 0) : DateTime.now();

      final nowUtc = DateTime.utc(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      // Calculate wait time in minutes
      final waitTimeMs = endAt - nowUtc.millisecondsSinceEpoch;
      final waitTime = waitTimeMs > 0 ? (waitTimeMs ~/ (1000 * 60)) : 0;
      final joinQueueTimeUtc = nowUtc.millisecondsSinceEpoch;

      print('[QUEUE] Calculated wait time: $waitTime minutes');

      // Create queue model for status update
      final queueModel = QueueModel(
          userId: userId,
          rideId: rideId,
          rideName: rideName,
          batchId: batchId,
          startAt: startAt,
          endAt: endAt,
          waitTime: waitTime,
          joinQueueTime: joinQueueTimeUtc, // Add new field

          status: 'waiting');
      print('[QUEUE] Created queue model: ${queueModel.toString()}');

      // Prepare the multi-path transaction
      final paths = [batchPath, '$_queueStatusPath/$userId/$rideId'];
      print('[QUEUE] Preparing transaction for paths: $paths');

      final updates = {
        '$batchPath/queueIds': queueIds,
        '$batchPath/queueFilledAt':
            queueIds.length >= rideModel.numOfRidersAllowed
                ? DateTime.now().toUtc().toIso8601String()
                : 'Not Filled Up',
        // Add queue status in the same transaction
        '$_queueStatusPath/$userId/$rideId': queueModel.toMap()
      };

      print('[QUEUE] Prepared updates for transaction: $updates');

      await _dbService.runMultiPathTransaction(updates: updates);
      print('[QUEUE] Successfully completed enqueue transaction');

      return {
        'success': true,
        'message': 'Successfully added to queue',
        'waitTime': waitTime
      };
    } catch (e) {
      print('[QUEUE] ERROR in enqueueVisitor: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Removes a user from a ride's batch queue and updates queue status.
  Future<Map<String, dynamic>> dequeueVisitor({
    required String userId,
    required String rideId,
    required String batchId,
  }) async {
    print('[QUEUE] Starting dequeueVisitor operation');

    try {
      // First, verify the batch exists and get current queueIds
      final batchPath = '$_ridesPath/$rideId/batches/$batchId';
      final batchData = await _dbService.read(batchPath);

      if (batchData == null) {
        print('[QUEUE] ERROR: Batch not found');
        return {'success': false, 'message': 'Batch not found'};
      }

      // Update queueIds list
      List<dynamic> queueIds = List.from(batchData['queueIds'] ?? ['empty']);
      queueIds.remove(userId);
      if (queueIds.isEmpty) queueIds = ['empty'];

      // Create precise path updates - only update specific fields
      final updates = {
        '$batchPath/queueIds': queueIds,
        '$batchPath/queueFilledAt': 'Not Filled Up'
      };

      print('[QUEUE] Updating specific fields: ${updates.keys}');
      await _dbService.runMultiPathTransaction(updates: updates);

      // Delete the user's queue status
      final statusPath = '$_queueStatusPath/$userId/$rideId';
      await _dbService.delete(statusPath);

      return {'success': true, 'message': 'Successfully removed from queue'};
    } catch (e) {
      print('[QUEUE] ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Gets a stream of all queue entries for a user
  Stream<List<QueueModel>> getUserQueues(String userId) {
    print('[QUEUE] Starting queue stream for user: $userId');

    return _dbService.streamData('$_queueStatusPath/$userId').map((event) {
      print('[QUEUE] Received queue stream event');

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('[QUEUE] No queue data found for user: $userId');
        return [];
      }

      print('[QUEUE] Processing ${data.length} queue entries');
      final queues = data.values
          .map((queueData) =>
              QueueModel.fromMap(Map<String, dynamic>.from(queueData as Map)))
          .toList();
      print('[QUEUE] Processed queue models: ${queues.length}');

      return queues;
    });
  }

  /// Helper method to check for time conflicts
  Future<Map<String, dynamic>> _checkTimeConflicts({
    required String userId,
    required int newStartAt,
    required int newEndAt,
  }) async {
    print(
        '[QUEUE] Checking time conflicts for batch ${DateTime.fromMillisecondsSinceEpoch(newStartAt)} to ${DateTime.fromMillisecondsSinceEpoch(newEndAt)}');

    // Get all current queues for the user
    final currentQueues = await getUserQueues(userId).first;

    // If no existing queues, no conflicts possible
    if (currentQueues.isEmpty) {
      return {'hasConflict': false};
    }

    // Check each existing queue for time overlap
    for (var existingQueue in currentQueues) {
      // A time conflict exists if:
      // 1. The new start time falls within an existing batch time OR
      // 2. The new end time falls within an existing batch time OR
      // 3. The new batch completely encompasses an existing batch
      bool hasOverlap = (newStartAt >= existingQueue.startAt &&
              newStartAt < existingQueue.endAt) ||
          (newEndAt > existingQueue.startAt &&
              newEndAt <= existingQueue.endAt) ||
          (newStartAt <= existingQueue.startAt &&
              newEndAt >= existingQueue.endAt);

      if (hasOverlap) {
        // Format times for error message
        final conflictStart =
            DateTime.fromMillisecondsSinceEpoch(existingQueue.startAt);
        final conflictEnd =
            DateTime.fromMillisecondsSinceEpoch(existingQueue.endAt);

        return {
          'hasConflict': true,
          'conflictingRide': existingQueue.rideName,
          'conflictTime':
              '${_formatTime(conflictStart.toUtc())} - ${_formatTime(conflictEnd.toUtc())}'
        };
      }
    }

    return {'hasConflict': false};
  }

// Helper to format time
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Gets a stream of queue status for a specific ride
  Stream<QueueModel?> getRideQueueStatus(String userId, String rideId) {
    print(
        '[QUEUE] Starting ride queue status stream - userId: $userId, rideId: $rideId');

    return _dbService
        .streamData('$_queueStatusPath/$userId/$rideId')
        .map((event) {
      print('[QUEUE] Received ride queue status event');

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        print('[QUEUE] No queue status found for user $userId on ride $rideId');
        return null;
      }

      print('[QUEUE] Processing queue status data: $data');
      final queueModel = QueueModel.fromMap(Map<String, dynamic>.from(data));
      print('[QUEUE] Created queue model: ${queueModel.toString()}');

      return queueModel;
    });
  }
}
