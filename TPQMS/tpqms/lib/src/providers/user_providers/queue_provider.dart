// queue_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/services/common_services/location_service.dart';
import 'package:tpqms/services/common_services/notification_service.dart';
import 'package:tpqms/services/common_services/queue_service.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/common_services/ticket_service.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/queue_model.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/providers/user_providers/location_provider.dart';

class QueueProvider extends ChangeNotifier {
  final QueueService _queueService;
  final TicketService _ticketService;
  final UserService _userService;
  final RideService _rideService;
  final NotificationService _notificationService;
  final LocationProvider _locationProvider; // Injected dependency

  bool _isLoading = false;
  List<QueueModel> _currentQueues = [];
  String? _error;
  Stream<List<QueueModel>>? _queueStream;
  StreamSubscription? _queueSubscription; // Add this

  // Getters
  bool get isLoading => _isLoading;
  List<QueueModel> get currentQueues => _currentQueues;
  String? get error => _error;
  Stream<List<QueueModel>>? get queueStream => _queueStream;
  int get queueCount => _currentQueues.length;

  QueueProvider(this._queueService, this._ticketService, this._userService,
      this._rideService, this._notificationService, this._locationProvider) {
    print('[QUEUE-PROVIDER] Initializing QueueProvider');
    initializeQueueStream();
  }

  /// Initializes the stream of queues for the current user
  Future<void> initializeQueueStream() async {
    print('[QUEUE-PROVIDER] Starting queue stream initialization');

    try {
      await _queueSubscription?.cancel();
      _queueSubscription = null;
      _currentQueues = [];

      final userId = await _userService.getCurrentUserUid();
      print('[QUEUE-PROVIDER] Retrieved current user ID: $userId');

      if (userId != null) {
        print('[QUEUE-PROVIDER] Setting up queue stream for user: $userId');
        _queueStream = _queueService.getUserQueues(userId);

        print('[QUEUE-PROVIDER] Attaching stream listener');
        _queueStream?.listen((queues) {
          print(
              '[QUEUE-PROVIDER] Queue update received - Count: ${queues.length}');
          _currentQueues = queues;
          print('[QUEUE-PROVIDER] Current queues updated. Details:');
          for (var queue in queues) {
            print(
                '[QUEUE-PROVIDER] - Ride: ${queue.rideId}, Batch: ${queue.batchId}, Status: ${queue.status}');
          }
          notifyListeners();
        }, onError: (error) {
          print('[QUEUE-PROVIDER] ERROR in queue stream: $error');
          _error = 'Failed to receive queue updates';
          notifyListeners();
        });
      } else {
        print(
            '[QUEUE-PROVIDER] ERROR: No user ID available for stream initialization');
      }
    } catch (e) {
      print('[QUEUE-PROVIDER] ERROR initializing queue stream: $e');
      _error = 'Failed to initialize queue stream';
      notifyListeners();
    }
  }

  /// Attempts to add a user to a ride queue
  Future<Map<String, dynamic>> queueForRide({
    required String rideId,
    required String batchId,
    required int startAt,
    required int endAt,
    required BuildContext context, // Add this parameter
  }) async {
    print('[QUEUE-PROVIDER] Starting queueForRide operation');
    print('[QUEUE-PROVIDER] Parameters:');
    print('  - Ride ID: $rideId');
    print('  - Batch ID: $batchId');
    print('  - Start Time: ${DateTime.fromMillisecondsSinceEpoch(startAt)}');
    print('  - End Time: ${DateTime.fromMillisecondsSinceEpoch(endAt)}');

    try {
      print('\n========== QUEUE OPERATION STARTED ==========');
      print('🚀 Starting queue operation for:');
      print('Ride ID: $rideId');
      print('Batch ID: $batchId');
      _setLoading(true);

      final userId = await _userService.getCurrentUserUid();
      print('\n👤 User Authentication Check:');
      print('Retrieved User ID: $userId');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('\n🎫 Checking Queue Limits...');
      final ridesQueued = await _ticketService.getRidesQueued(userId);
      print('Current Rides Queued: $ridesQueued');

      if (ridesQueued >= 2) {
        print('❌ Queue limit reached!');
        throw Exception('Maximum number of rides queued (2) reached');
      }

      print('\n🎫 Checking Queue Limits...');
      final ridesMissed = await _ticketService.getMissedQueue(userId);
      print('Current Rides Queued: $ridesQueued');

      if (ridesMissed >= 3) {
        print('❌ Missed queue limit reached!');
        throw Exception(
            'You have missed 3 queues already, please contact admin. You can only queue manually from now on.');
      }

      print('\n🎟️ Validating Ticket...');
      final ticket = await _ticketService.getTicketByUserId(userId);
      print('Ticket Status: ${ticket != null ? "Found" : "Not Found"}');

      if (ticket == null) {
        print('❌ No valid ticket found!');
        throw Exception('No valid ticket found');
      }

      print('\n📝 Attempting to Queue User...');
      print('Calling enqueueVisitor with:');
      print('User ID: $userId');
      print('Ride ID: $rideId');
      print('Batch ID: $batchId');

      final result = await _queueService.enqueueVisitor(
        userId: userId,
        rideId: rideId,
        batchId: batchId,
        startAt: startAt,
        endAt: endAt,
      );

      print('\n🔄 Queue Operation Result:');
      print('Raw Result: $result');
      print('Success Status: ${result['success']}');
      print('Message: ${result['message']}');

      if (result['success']) {
        print('\n✨ Queue Successful! Updating ticket count...');
        final ride = await _rideService.getRideById(rideId);
        final batch = await _rideService.getBatchById(rideId, batchId);
        if (ride != null && batch != null) {
          await _notificationService.scheduleRideNotification(
            ride,
            batch,
            const Duration(minutes: 1),
          );
          await _notificationService.sendImmediateEnqueueNotification(
              ride, batch);
        }
        await _locationProvider.startMonitoringRide(ride!); // Add this
        await _ticketService.updateRidesQueued(ticket.ticketId, 1);
        print('✅ Ticket count updated successfully');
      }

      print('\n📤 Returning Result:');
      print('Success: ${result['success']}');
      print('Message: ${result['message']}');

      return result;
    } catch (e) {
      print('\n❌ ERROR in queueForRide:');
      print('Error Message: $e');
      _handleError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
      print('\n========== QUEUE OPERATION COMPLETED ==========\n');
      notifyListeners();
    }
  }

  /// Attempts to remove a user from a ride queue
  Future<Map<String, dynamic>> dequeueFromRide({
    required String rideId,
    required String batchId,
    required BuildContext context, // Add this parameter
  }) async {
    print('[QUEUE-PROVIDER] Starting dequeueFromRide operation');
    print('[QUEUE-PROVIDER] Parameters:');
    print('  - Ride ID: $rideId');
    print('  - Batch ID: $batchId');

    try {
      _setLoading(true);

      // Get current user ID
      final userId = await _userService.getCurrentUserUid();
      print('[QUEUE-PROVIDER] Retrieved user ID: $userId');

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get ticket to update rides queued count
      final ticket = await _ticketService.getTicketByUserId(userId);
      print('[QUEUE-PROVIDER] Retrieved ticket: ${ticket?.ticketId}');

      if (ticket == null) {
        print('[QUEUE-PROVIDER] ERROR: No valid ticket found');
        throw Exception('No valid ticket found');
      }

      // Attempt to dequeue the user
      print('[QUEUE-PROVIDER] Attempting to dequeue user');
      final result = await _queueService.dequeueVisitor(
        userId: userId,
        rideId: rideId,
        batchId: batchId,
      );
      final ride = await _rideService.getRideById(rideId);
      final batch = await _rideService.getBatchById(rideId, batchId);

      print('[QUEUE-PROVIDER] Dequeue attempt result: $result');

      if (result['success']) {
        print(
            '[QUEUE-PROVIDER] Dequeue successful, updating ticket rides count');
        await _notificationService.cancelRideNotification(batch);
        print('[QUEUE-PROVIDER] Notification cancelled successfully');
        await _ticketService.updateRidesQueued(ticket.ticketId, -1);
        print('[QUEUE-PROVIDER] Ticket updated successfully');
        await _locationProvider.stopMonitoringRide(rideId);
        await _notificationService.sendImmediateDequeueNotification(
            ride!, batch);
      }

      _setLoading(false);
      return result;
    } catch (e) {
      print('[QUEUE-PROVIDER] ERROR in dequeueFromRide: $e');
      _handleError(e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Gets the queue status for a specific ride
  Stream<QueueModel?> getRideQueueStatus(String rideId) async* {
    print('[QUEUE-PROVIDER] Getting queue status for ride: $rideId');

    try {
      final userId = await _userService.getCurrentUserUid();
      print('[QUEUE-PROVIDER] Retrieved user ID: $userId');

      if (userId == null) {
        print('[QUEUE-PROVIDER] ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('[QUEUE-PROVIDER] Starting queue status stream');
      yield* _queueService.getRideQueueStatus(userId, rideId);
    } catch (e) {
      print('[QUEUE-PROVIDER] ERROR getting ride queue status: $e');
      _handleError(e.toString());
      yield null;
    }
  }

  // Add this method for testing
  // Future<void> testNotification(RideModel ride, BatchModel batch) async {
  //   final success = await _locationService.scheduleRideNotification(
  //     ride,
  //     batch,
  //     const Duration(minutes: 1), // Test with 1 minute for quick feedback
  //   );

  //   if (success) {
  //     print('Test notification scheduled successfully');
  //   } else {
  //     print('Failed to schedule test notification');
  //   }
  // }

  // New method to refresh wait times for all current queues
  Future<void> refreshQueueWaitTimes() async {
    print('[QUEUE-PROVIDER] Refreshing queue wait times');
    try {
      _setLoading(true);

      // Get current queues - no need to fetch from database since we're just
      // recalculating wait times based on current time
      _currentQueues = _currentQueues.map((queue) {
        // Create a new queue model with updated wait time
        final currentWaitTime = queue.calculateCurrentWaitTime();
        return QueueModel(
          userId: queue.userId,
          rideId: queue.rideId,
          rideName: queue.rideName,
          batchId: queue.batchId,
          startAt: queue.startAt,
          endAt: queue.endAt,
          joinQueueTime: queue.joinQueueTime,
          waitTime: currentWaitTime, // Update the wait time
          status: queue.status,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('[QUEUE-PROVIDER] Error refreshing wait times: $e');
      _handleError('Failed to refresh wait times');
    } finally {
      _setLoading(false);
    }
  }

  // Method to be called when queue page is opened
  Future<void> onQueuePageOpened() async {
    print('[QUEUE-PROVIDER] Queue page opened, refreshing data');
    await refreshQueueWaitTimes();
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    print('[QUEUE-PROVIDER] Setting loading state to: $loading');
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  void _handleError(String error) {
    print('[QUEUE-PROVIDER] Handling error: $error');
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  /// Clears any error messages
  void clearError() {
    print('[QUEUE-PROVIDER] Clearing error state');
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    super.dispose();
  }

  // void reset() {
  //   _queueStream?.listen(null).cancel();
  //   _queueStream = null;
  //   _currentQueues = [];
  //   _error = null;
  //   notifyListeners();
  // }

  // Example for RideProvider
  Future<void> reset() async {
    try {
      print('[QUEUE-PROVIDER] Starting reset...');

      await _queueSubscription?.cancel();
      _queueStream = null;
      _currentQueues = [];
      _error = null;
      // Notify listeners AFTER cleanup
      notifyListeners();

      print('[QUEUE-PROVIDER] Reset completed');
    } catch (e) {
      print('[QUEUE-PROVIDER] Error during reset: $e');
    }
  }
}
