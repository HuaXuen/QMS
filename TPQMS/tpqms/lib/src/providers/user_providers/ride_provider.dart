import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService;
  //List<RideModel> _rides = [];
  bool _isLoading = false;
  StreamSubscription<List<RideModel>>? _ridesSubscription;
  final RealtimeDbService _realtimeDbService;
  bool _isTestMode = false; // Add this flag
  Map<String, RideModel> _rideState = {}; // Use map for better state management

  RideProvider(this._rideService, this._realtimeDbService) {
    _subscribeToRides();
  }

  // Getters
  List<RideModel> get rides => _rideState.values.toList();
  bool get isLoading => _isLoading;
  int get rideCount => _rideState.length;
  Stream<List<RideModel>> get ridesStream {
    return _rideService.streamRidesWithBatches().map((rides) {
      // Validate each ride has complete data before emitting
      return rides.where((ride) => _isRideDataComplete(ride)).toList();
    });
  }

  Future<void> refreshRides() async {
    print("[RIDES-STATE] Starting complete ride refresh");

    try {
      // 1. Clear Firebase's persistence first
      await FirebaseDatabase.instance.purgeOutstandingWrites();

      // 2. Force disconnect and reconnect
      await FirebaseDatabase.instance.goOffline();
      await FirebaseDatabase.instance.goOnline();

      // 3. Clear our local state
      _rideState.clear();

      // 4. Cancel existing subscription
      await _ridesSubscription?.cancel();

      // 5. Wait a brief moment for Firebase to stabilize
      await Future.delayed(Duration(milliseconds: 500));

      // 6. Resubscribe with fresh connection
      _subscribeToRides();

      print("[RIDES-STATE] Refresh completed successfully");
    } catch (e) {
      print("[RIDES-STATE] Error during refresh: $e");
      // Re-establish connection if something went wrong
      FirebaseDatabase.instance.goOnline();
    }
  }

  bool _isRideDataComplete(RideModel ride) {
    return ride.name != null && ride.status != null && ride.batches != null;
  }

  void _subscribeToRides() {
    _ridesSubscription?.cancel();
    _ridesSubscription = _rideService
        .streamRidesWithBatches()
        .handleError((error) {
          print("[RIDES-STATE] Error in stream: $error");
          return []; // Return empty list on error
        })
        .where((rides) => rides.isNotEmpty) // Only emit non-empty updates
        .listen((updatedRides) {
          print("[RIDES-STATE] Received ${updatedRides.length} rides update");
          for (var ride in updatedRides) {
            _rideState[ride.id] = _mergeRideData(_rideState[ride.id], ride);
          }
          // Log the state change
          print(
              "[RIDES-STATE] State updated: ${_rideState.length} rides in state");
          for (var ride in updatedRides) {
            print("[RIDES-STATE] Ride in state: "
                "id=${ride.id}, "
                "status=${ride.status}");
          }

          notifyListeners();
        }, onError: (error) {
          print("[RIDES-STATE] Error in subscription: $error");
          notifyListeners();
        });
  }

  RideModel _mergeRideData(RideModel? existing, RideModel updated) {
    if (existing == null) return updated;

    // Preserve existing data if new data is incomplete
    return RideModel(
      id: updated.id,
      name: updated.name ?? existing.name,
      category: updated.category ?? existing.category,
      status: updated.status ?? existing.status,
      batches: updated.batches ?? existing.batches,
      heightRequirement:
          updated.heightRequirement ?? existing.heightRequirement,
      queueTime: updated.queueTime ?? existing.queueTime,
      numOfRidersAllowed:
          updated.numOfRidersAllowed ?? existing.numOfRidersAllowed,
      currentBatchId: updated.currentBatchId ?? existing.currentBatchId,
      createdAt: updated.createdAt ?? existing.createdAt,
    );
  }

  Future<BatchModel?> getBatchById(String rideId, String batchId) async {
    try {
      final batchPath = 'rides/$rideId/batches/$batchId';
      final data = await _realtimeDbService.read(batchPath);

      if (data == null) {
        return null;
      }

      return BatchModel.fromMap(batchId, Map<String, dynamic>.from(data));
    } catch (e) {
      print('Error getting batch: $e');
      return null;
    }
  }

// // In RideProvider
  // Stream<List<RideModel>> getClosedRidesStream() {
  //   return ridesStream.map((rides) => rides
  //       .where((ride) => ride.status.toLowerCase() != 'available')
  //       .toList());
  // }

  // Stream<List<RideModel>> getAvailableRidesStream() {
  //   return ridesStream.map((rides) => rides
  //       .where((ride) => ride.status.toLowerCase() == 'available')
  //       .toList());
  // }

  // Add method to get ride from cache
  // RideModel? getRideFromCache(String rideId) => _rideCache[rideId];

  Stream<List<RideModel>> getAvailableRidesStream() {
    return ridesStream.map((rides) {
      print("[DEBUG] Processing ${rides.length} rides for available status");

      final filteredRides = rides.where((ride) {
        final isAvailable = ride.status.toLowerCase() == 'available';
        print(
            "[DEBUG] Ride ${ride.id}: status=${ride.status}, available=$isAvailable");
        return isAvailable;
      }).toList();

      print("[DEBUG] Found ${filteredRides.length} available rides");
      return filteredRides;
    });
  }

  Stream<List<RideModel>> getClosedRidesStream() {
    return ridesStream.map((rides) {
      print("[DEBUG] Processing ${rides.length} rides for closed status");

      final filteredRides = rides.where((ride) {
        final isClosed = ride.status.toLowerCase() != 'available';
        print(
            "[DEBUG] Ride ${ride.id}: status=${ride.status}, closed=$isClosed");
        return isClosed;
      }).toList();

      print("[DEBUG] Found ${filteredRides.length} closed rides");
      return filteredRides;
    });
  }

  // CRUD operations through service
  Future<String?> addRide({
    required String name,
    required String category,
    required String status,
    required int heightRequirement,
    required int queueTime,
    required int numOfRidersAllowed,
    required double latitude,
    required double longitude,
    required double radiusInMeters,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      print(
          'Adding ride with details: $name, $category, $status, $heightRequirement, $queueTime, $numOfRidersAllowed');
      final rideId = await _rideService.addRide(
        name: name,
        category: category,
        status: status,
        heightRequirement: heightRequirement,
        queueTime: queueTime,
        numOfRidersAllowed: numOfRidersAllowed,
        createdAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        radiusInMeters: radiusInMeters,
      );
      print('Ride added successfully: $rideId');
      _isLoading = false;
      notifyListeners();
      return rideId;
    } catch (e) {
      print('Error adding ride in provider: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Stream<List<BatchModel>> streamAvailableBatchesForRide(String rideId) {
  //   return _rideService.streamBatches(rideId).map((batches) {
  //     // Get the current time and explicitly convert to UTC
  //     final now = DateTime.now();
  //     final nowUtc = DateTime.utc(
  //       now.year,
  //       now.month,
  //       now.day,
  //       now.hour,
  //       now.minute,
  //       now.second,
  //     );

  //     // Calculate the end of the current hour in UTC
  //     final endOfHour = DateTime.utc(
  //       nowUtc.year,
  //       nowUtc.month,
  //       nowUtc.day,
  //       nowUtc.hour + 1,
  //     );

  //     print('Raw Now: $now');
  //     print(
  //         'Local Time Zone: ${now.timeZoneName}, Offset: ${now.timeZoneOffset}');
  //     print('UTC Now: $nowUtc');
  //     print('End of Hour (UTC): $endOfHour');

  //     final filteredBatches = batches.where((batch) {
  //       final startTime =
  //           DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
  //       final endTime =
  //           DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

  //       debugPrint('Batch ID: ${batch.id}, Start: $startTime, End: $endTime');
  //       debugPrint(
  //           'isAfter(now): ${startTime.isAfter(nowUtc)}, isBefore(endOfHour): ${startTime.isBefore(endOfHour)}');

  //       return endTime.isAfter(nowUtc) && startTime.isBefore(endOfHour);
  //     }).toList();

  //     notifyListeners();
  //     print("HEREE Filtered Batches: $filteredBatches");
  //     return filteredBatches;
  //   });
  // }

  Stream<List<BatchModel>> streamAvailableBatchesForRide(String rideId) async* {
    try {
      final ride = await _rideService.getRideById(rideId);
      if (ride == null) {
        print('No ride found for rideId=$rideId');
        yield [];
        return;
      }

      await for (final batches in _rideService.streamBatches(rideId)) {
        final now = _isTestMode ? DateTime(2025, 1, 1, 14, 0) : DateTime.now();

        //now = DateTime.now();
        final nowUtc = DateTime.utc(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
          now.second,
        );

        final endOfHour = DateTime.utc(
          nowUtc.year,
          nowUtc.month,
          nowUtc.day,
          nowUtc.hour + 1,
        );

        print('Current time (UTC): $nowUtc, End of hour (UTC): $endOfHour');

        // Log all batches fetched from the service
        // print('Processing batches. Current time: $nowUtc');
        // for (var batch in batches) {
        //   print(
        //       'Batch ${batch.id}: startAt=${batch.startAt}, endAt=${batch.endAt}');
        // }

        final filteredBatches = batches.where((batch) {
          final startTime =
              DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
          final endTime =
              DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

          // Check if batch is in the future and within the next hour
          bool isTimeValid =
              endTime.isAfter(nowUtc) && startTime.isBefore(endOfHour);

          // Check if batch is not completed
          bool isAvailable = batch.completedAt == 0;

          // Check if batch is not full using ride's numOfRidersAllowed
          bool isNotFull = batch.queueIds.length < ride.numOfRidersAllowed;

          // UNCOMMENT FOR DEBUG Log the conditions for each batch
          // print(
          //     'Batch ID: ${batch.id} -> isTimeValid: $isTimeValid, isAvailable: $isAvailable, isNotFull: $isNotFull');

          return isTimeValid && isAvailable && isNotFull;
        }).toList();

        //UNCOMMENT FOR DEBUG Log filtered batches
        // print(
        //     'Filtered ${filteredBatches.length} batches after applying filters:');
        // for (var batch in filteredBatches) {
        //   print(
        //       'Batch ID: ${batch.id}, Start At: ${batch.startAt}, End At: ${batch.endAt}, Queue IDs: ${batch.queueIds.length}');
        // }

        // Sort by start time
        filteredBatches.sort((a, b) => a.startAt.compareTo(b.startAt));

        // Yield the filtered batches
        yield filteredBatches;
      }
    } catch (e) {
      print('Error in streamAvailableBatchesForRide: $e');
      yield [];
    }
  }

  Future<void> closeRide(String rideId) async {
    try {
      // Path to the specific ride
      String path = 'rides/$rideId';

      // Get the ride data
      var rideData = await _realtimeDbService.read(path);

      // Check if data exists and get the 'status' field
      if (rideData != null && rideData.containsKey('status')) {
        String status = rideData['status'];
        if (status == 'available') {
          await _rideService.updateRideStatus(rideId, 'closed');
          debugPrint('Ride is available. Proceeding to close the ride...');
        } else {
          debugPrint('Ride is not available to close.');
        }
      } else {
        debugPrint('Ride data not found for ID: $rideId');
      }
    } catch (e) {
      debugPrint('Error closing ride: $e');
    }
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    notifyListeners();
    super.dispose();
  }

  Future<void> reset() async {
    try {
      print('[RIDE-PROVIDER] Starting reset...');

      // Cancel existing subscriptions
      _ridesSubscription?.cancel();

      // Clear cached data
      _rideState.clear();

      // Reset state flags
      _isLoading = false;

      // Notify listeners AFTER cleanup
      notifyListeners();

      print('[RIDE-PROVIDER] Reset completed');
    } catch (e) {
      print('[RIDE-PROVIDER] Error during reset: $e');
    }
  }
}
