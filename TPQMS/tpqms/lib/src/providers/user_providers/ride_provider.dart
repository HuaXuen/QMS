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
  Stream<List<RideModel>> get ridesStream => _rideService.streamRides();

  void _subscribeToRides() {
    _ridesSubscription?.cancel();
    _ridesSubscription = _rideService.streamRides().listen((updatedRides) {
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

  // Business logic methods
  List<RideModel> getRidesByCategory(String category) {
    return _rides.where((ride) => ride.category == category).toList();
  }

  List<RideModel> getRidesByStatus(String status) {
    return _rides.where((ride) => ride.status == status).toList();
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
    try {
      // Step 1: Prepare the Ride Data (without ID yet)
      final newRide = RideModel(
          name: name,
          category: category,
          status: status,
          heightRequirement: heightRequirement,
          queueTime: queueTime,
          numOfRidersAllowed: numOfRidersAllowed,
          currentBatchId: '');
      var mappedNewRide = newRide.toMap();
      // Step 2: Generate the Ride ID using the backend
      final rideId = await _rideService.addRideWithAutoId(mappedNewRide);
      final batchId = await _rideService.generateBatchId(rideId!);

      // Step 3: Create the first batch
      final firstBatch = BatchModel(
          id: batchId,
          rideId: rideId,
          queueIds: ['empty'],
          batchStatus: 'pending',
          createdAt: DateTime.now().millisecondsSinceEpoch);
      var mappedFirstBatch = firstBatch.toMap();
      // Step 4: Update both Ride and First Batch Atomically
      await _rideService.addRideAndBatch(
          rideId, mappedNewRide, batchId, mappedFirstBatch);

      await _rideService.generateTimeslots(
          rideId, 12); // 12 slots = 4 hours of batches
      print('Ride and first batch added successfully with ID: $rideId');
      return rideId; // Return the Ride ID
    } catch (e) {
      debugPrint('Error adding ride with batch: $e');
      return null;
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
    super.dispose();
  }
}
