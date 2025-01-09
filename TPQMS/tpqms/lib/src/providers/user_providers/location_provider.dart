// location_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tpqms/services/common_services/location_service.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/src/model/ride_model.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final RideService _rideService;

  // State management
  bool _isInitialized = false;
  bool _isTracking = false;
  Position? _currentPosition;
  String? _error;
  final Map<String, double> _rideDistances = {};
  final Set<String> _monitoredRideIds = {};
  Timer? _monitoringTimer;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;

  // Stream subscription management
  StreamSubscription<Position>? _locationSubscription;

  LocationProvider(this._locationService, this._rideService);

  // Initialize location services
  Future<bool> initialize() async {
    print('[LOCATION-PROVIDER] Starting initialization...');
    try {
      _error = null;
      print('[LOCATION-PROVIDER] Calling LocationService.initialize()');
      final initialized = await _locationService.initialize();

      if (initialized) {
        print('[LOCATION-PROVIDER] Successfully initialized');
        _isInitialized = true;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to initialize location services';
        print('[LOCATION-PROVIDER] Initialization failed: $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error initializing location services: $e';
      print('[LOCATION-PROVIDER] Error during initialization: $_error');
      notifyListeners();
      return false;
    }
  }

  Future<void> startMonitoringRide(RideModel ride) async {
    print(
        '[LOCATION-PROVIDER] Starting to monitor ride: ${ride.name} (${ride.id})');
    print(
        '[LOCATION-PROVIDER] Current monitored rides before adding: ${_monitoredRideIds.toString()}'); // Add this
    if (!_isTracking) {
      print('[LOCATION-PROVIDER] Location tracking not active, starting...');
      final success = await startTracking();
      if (!success) {
        print('[LOCATION-PROVIDER] Failed to start location tracking');
        return;
      }
    }

    if (!_monitoredRideIds.contains(ride.id)) {
      print('[LOCATION-PROVIDER] Adding ride to monitored set');
      _monitoredRideIds.add(ride.id);
      print(
          '[LOCATION-PROVIDER] Updated monitored rides: ${_monitoredRideIds.toString()}'); // Add this

      if (_monitoringTimer == null) {
        print(
            '[LOCATION-PROVIDER] Initializing periodic monitoring timer (30s interval)');
        _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          print(
              '[LOCATION-PROVIDER] Timer triggered - checking all monitored rides');
          print(
              '[LOCATION-PROVIDER] Currently monitored rides: ${_monitoredRideIds.toString()}'); // Add this
          if (_currentPosition != null) {
            // Add explicit position check

            _checkAllMonitoredRides();
          }
        });
        if (_currentPosition != null) {
          _checkAllMonitoredRides();
        }

        notifyListeners();
      } else {
        print('[LOCATION-PROVIDER] Monitoring timer already running');
      }

      print(
          '[LOCATION-PROVIDER] Currently monitoring ${_monitoredRideIds.length} rides');
      print(
          '[LOCATION-PROVIDER] Monitored rides IDs: ${_monitoredRideIds.toString()}'); // Add this

      notifyListeners();
    } else {
      print('[LOCATION-PROVIDER] Ride ${ride.id} is already being monitored');
      print(
          '[LOCATION-PROVIDER] Current monitored rides: ${_monitoredRideIds.toString()}'); // Add this
    }
  }

  void _checkAllMonitoredRides() async {
    print('[LOCATION-PROVIDER] Starting periodic check of all monitored rides');

    if (!_isTracking || _currentPosition == null) {
      print(
          '[LOCATION-PROVIDER] Cannot check rides - tracking disabled or no position');
      return;
    }

    print('[LOCATION-PROVIDER] Current position: $_currentPosition');
    print(
        '[LOCATION-PROVIDER] Checking ${_monitoredRideIds.length} monitored rides');

    for (final rideId in _monitoredRideIds) {
      print('[LOCATION-PROVIDER] Fetching ride data for ID: $rideId');
      final ride = await _rideService.getRideById(rideId);

      if (ride != null) {
        print('[LOCATION-PROVIDER] Monitoring distance for ride: ${ride.name}');
        await _locationService.monitorRideDistance(ride);
      } else {
        print(
            '[LOCATION-PROVIDER] WARNING: Could not fetch ride data for ID: $rideId');
      }
    }
    print('[LOCATION-PROVIDER] Completed checking all monitored rides');
  }

  Future<void> stopMonitoringRide(String rideId) async {
    print('[LOCATION-PROVIDER] Stopping monitoring for ride: $rideId');
    print(
        '[LOCATION-PROVIDER] Current monitored rides before removal: ${_monitoredRideIds.toString()}'); // Add this
    print(
        '[LOCATION-PROVIDER] Contains ride? ${_monitoredRideIds.contains(rideId)}'); // Add this

    if (_monitoredRideIds.remove(rideId)) {
      print('[LOCATION-PROVIDER] Successfully removed ride from monitoring');
      print(
          '[LOCATION-PROVIDER] Updated monitored rides: ${_monitoredRideIds.toString()}'); // Add this
      if (_monitoredRideIds.isEmpty) {
        print('[LOCATION-PROVIDER] No more rides to monitor, canceling timer');
        _monitoringTimer?.cancel();
        _monitoringTimer = null;
      }

      print(
          '[LOCATION-PROVIDER] Now monitoring ${_monitoredRideIds.length} rides');
      print(
          '[LOCATION-PROVIDER] Remaining monitored rides: ${_monitoredRideIds.toString()}'); // Add this
      notifyListeners();
    } else {
      print('[LOCATION-PROVIDER] Ride $rideId was not being monitored');
      print(
          '[LOCATION-PROVIDER] Current monitored rides: ${_monitoredRideIds.toString()}'); // Add this
    }
  }

  // Start tracking user location
  Future<bool> startTracking() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      final success = await _locationService.startTracking();

      if (success) {
        _isTracking = true;

        // Subscribe to location updates
        _locationSubscription = _locationService.locationStream.listen(
          (position) {
            print(
                '[LOCATION-PROVIDER] Received position update: $position'); // Add debug log

            _currentPosition = position;
            if (_monitoredRideIds.isNotEmpty) {
              _checkAllMonitoredRides();
            }
            notifyListeners();
          },
          onError: (error) {
            print('[LOCATION-PROVIDER] Location stream error: $error');

            _error = 'Location tracking error: $error';
            notifyListeners();
          },
        );

        notifyListeners();
        return true;
      }

      _error = 'Failed to start location tracking';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error starting location tracking: $e';
      notifyListeners();
      return false;
    }
  }

  // Monitor distance to queued rides
  Future<void> getDistanceBetweenUserAndQueuedRides(
      List<RideModel> queuedRides) async {
    if (!_isTracking || _currentPosition == null) return;

    try {
      for (final ride in queuedRides) {
        // Update distances map
        if (ride.latitude != null && ride.longitude != null) {
          final distance = _locationService.calculateDistanceToRide(ride);
          _rideDistances[ride.id] = distance;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error monitoring queued rides: $e';
      notifyListeners();
    }
  }

  // Get distance to a specific ride
  double? getDistanceToRide(String rideId) => _rideDistances[rideId];

  // Check if within geofence of a ride
  bool isWithinRideGeofence(RideModel ride) {
    if (!hasLocation) return false;
    return _locationService.isWithinRideGeofence(ride);
  }

  // Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  // Reset state (for cleanup during logout etc.)
  Future<void> reset() async {
    try {
      print('[LOCATION-PROVIDER] Starting reset...');

      await _locationSubscription?.cancel();
      await _locationService.dispose();

      _isInitialized = false;
      _isTracking = false;
      _currentPosition = null;
      _error = null;
      _rideDistances.clear();

      notifyListeners();

      print('[LOCATION-PROVIDER] Reset completed');
    } catch (e) {
      print('[LOCATION-PROVIDER] Error during reset: $e');
      _error = 'Error during reset: $e';
      notifyListeners();
    }
  }
}
