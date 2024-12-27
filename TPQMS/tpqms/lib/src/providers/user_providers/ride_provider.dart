import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService;
  List<RideModel> _rides = [];
  bool _isLoading = false;
  StreamSubscription<List<RideModel>>? _ridesSubscription;
  final RealtimeDbService _realtimeDbService;

  RideProvider(this._rideService, this._realtimeDbService) {
    _subscribeToRides();
  }

  // Getters
  List<RideModel> get rides => _rides;
  bool get isLoading => _isLoading;
  int get rideCount => _rides.length;
  Stream<List<RideModel>> get ridesStream =>
      _rideService.streamRidesWithBatches();

  void _subscribeToRides() {
    _ridesSubscription?.cancel();
    _ridesSubscription =
        _rideService.streamRidesWithBatches().listen((updatedRides) {
      _rides = updatedRides;
      print("${_rides}");
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error in ride stream: $error');
      _rides = [];
      notifyListeners();
    });
  }

// In RideProvider
  Stream<List<RideModel>> getClosedRidesStream() {
    return ridesStream.map((rides) => rides
        .where((ride) => ride.status.toLowerCase() != 'available')
        .toList());
  }

  Stream<List<RideModel>> getAvailableRidesStream() {
    return ridesStream.map((rides) => rides
        .where((ride) => ride.status.toLowerCase() == 'available')
        .toList());
  }

  // CRUD operations through service
  Future<String?> addRide({
    required String name,
    required String category,
    required String status,
    required int heightRequirement,
    required int queueTime,
    required int numOfRidersAllowed,
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

  Stream<List<BatchModel>> streamAvailableBatchesForRide(String rideId) {
    return _rideService.streamBatches(rideId).map((batches) {
      // Get the current time and explicitly convert to UTC
      final now = DateTime.now();
      final nowUtc = DateTime.utc(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );

      // Calculate the end of the current hour in UTC
      final endOfHour = DateTime.utc(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        nowUtc.hour + 1,
      );

      print('Raw Now: $now');
      print(
          'Local Time Zone: ${now.timeZoneName}, Offset: ${now.timeZoneOffset}');
      print('UTC Now: $nowUtc');
      print('End of Hour (UTC): $endOfHour');

      final filteredBatches = batches.where((batch) {
        final startTime =
            DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
        final endTime =
            DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

        debugPrint('Batch ID: ${batch.id}, Start: $startTime, End: $endTime');
        debugPrint(
            'isAfter(now): ${startTime.isAfter(nowUtc)}, isBefore(endOfHour): ${startTime.isBefore(endOfHour)}');

        return endTime.isAfter(nowUtc) && startTime.isBefore(endOfHour);
      }).toList();

      notifyListeners();
      print("HEREE Filtered Batches: $filteredBatches");
      return filteredBatches;
    });
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
    super.dispose();
  }
}
