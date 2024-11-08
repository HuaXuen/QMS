import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tpqms/services/ride_service.dart';
import 'package:tpqms/src/model/ride_model.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService;
  List<RideModel> _rides = [];
  bool _isLoading = false;
  StreamSubscription<List<RideModel>>? _ridesSubscription;

  RideProvider(this._rideService) {
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

  List<RideModel> getRidesAvailable() {
    print("${_rides}");
    return _rides
        .where((ride) => ride.status.toLowerCase() == 'available'.toLowerCase())
        .toList();
  }

  List<RideModel> getRidesClosed() {
    print("${_rides}");
    return _rides
        .where((ride) => ride.status.toLowerCase() != 'available'.toLowerCase())
        .toList();
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
  Future<void> addRide({
    required String name,
    required String category,
    required String status,
    required int heightRequirement,
    required int queueTime,
  }) async {
    final newRide = RideModel(
      name: name,
      category: category,
      status: status,
      heightRequirement: heightRequirement,
      queueTime: queueTime,
    );

    await _rideService.createRide(newRide);
  }

  Future<void> deleteRide(String rideId) async {
    await _rideService.deleteRide(rideId);
  }

  @override
  void dispose() {
    _ridesSubscription?.cancel();
    super.dispose();
  }
}
