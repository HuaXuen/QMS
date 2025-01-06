// location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tpqms/services/common_services/notification_service.dart';
import 'package:tpqms/src/model/ride_model.dart';

class LocationService {
  // Dependencies
  final NotificationService _notificationService;

  // Stream controllers
  final _locationController = StreamController<Position>.broadcast();
  StreamSubscription<Position>? _locationSubscription;

  // Service state
  bool _isInitialized = false;
  Position? _lastKnownPosition;
  final Map<String, DateTime> _lastNotificationTimes = {};

  // Constants
  static const int _minimumNotificationInterval = 300; // 5 minutes in seconds
  static const double _defaultGeofenceRadius = 100.0; // meters

  LocationService(this._notificationService);

  // Getter for the location stream
  Stream<Position> get locationStream => _locationController.stream;

  // Initialize location services and request permissions
  Future<bool> initialize() async {
    print('[LOCATION-SERVICE] Starting initialization...');
    if (_isInitialized) {
      print('[LOCATION-SERVICE] Already initialized, returning');
      return true;
    }

    try {
      // Check if location services are enabled
      print('[LOCATION-SERVICE] Checking if location services are enabled');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LOCATION-SERVICE] Location services are disabled');
        return false;
      }

      // Check location permission
      print('[LOCATION-SERVICE] Requesting location permission');
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        print('[LOCATION-SERVICE] Location permission denied: $permission');
        return false;
      }

      // Get the last known position
      try {
        print('[LOCATION-SERVICE] Getting last known position');
        _lastKnownPosition = await Geolocator.getLastKnownPosition();
        print('[LOCATION-SERVICE] Last known position: $_lastKnownPosition');
      } catch (e) {
        print('[LOCATION-SERVICE] Error getting last position: $e');
      }

      _isInitialized = true;
      print('[LOCATION-SERVICE] Initialization completed successfully');
      return true;
    } catch (e) {
      print('[LOCATION-SERVICE] Error during initialization: $e');
      return false;
    }
  }

  // Start tracking location
  Future<bool> startTracking() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // Configure location settings for optimal battery usage
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      // Start listening to location updates
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _locationController.add(position);
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
          _locationController.addError(error);
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  // Calculate distance to a ride
  double calculateDistanceToRide(RideModel ride) {
    print('[LOCATION-SERVICE] Calculating distance to ride: ${ride.name}');

    if (_lastKnownPosition == null) {
      print(
          '[LOCATION-SERVICE] No position available for distance calculation');
      return double.infinity;
    }

    if (ride.latitude == null || ride.longitude == null) {
      print('[LOCATION-SERVICE] No ride coordinates available for calculation');
      return double.infinity;
    }

    final distance = Geolocator.distanceBetween(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      ride.latitude!,
      ride.longitude!,
    );

    print(
        '[LOCATION-SERVICE] Calculated distance: ${distance.toStringAsFixed(2)}m');
    return distance;
  }

  // Check if user is within ride's geofence
  bool isWithinRideGeofence(RideModel ride) {
    final distance = calculateDistanceToRide(ride);
    return distance <= (ride.radiusInMeters ?? _defaultGeofenceRadius);
  }

  // Monitor distance to queued ride
  Future<void> monitorRideDistance(RideModel ride) async {
    print(
        '[LOCATION-SERVICE] Starting distance check for ride: ${ride.name} (${ride.id})');

    if (_lastKnownPosition == null) {
      print('[LOCATION-SERVICE] No last known position available');
      return;
    }

    if (ride.latitude == null || ride.longitude == null) {
      print('[LOCATION-SERVICE] Ride coordinates not available');
      return;
    }

    final distance = calculateDistanceToRide(ride);
    final distanceToPrint = '${distance.toStringAsFixed(2)} meters';
    final radius = ride.radiusInMeters ?? _defaultGeofenceRadius;

    print(
        '[LOCATION-SERVICE] Current distance to ride: ${distance.toStringAsFixed(2)}m');
    print('[LOCATION-SERVICE] Allowed radius: ${radius}m');

    if (distance > radius) {
      print('[LOCATION-SERVICE] User has moved beyond allowed radius');

      if (!_lastNotificationTimes.containsKey(ride.id)) {
        print('[LOCATION-SERVICE] Sending first-time warning notification');
        await _notificationService.sendDistanceWarningNotification(
            ride, distanceToPrint);
        _lastNotificationTimes[ride.id] = DateTime.now();
        print('[LOCATION-SERVICE] Warning notification sent and recorded');
      } else {
        final lastNotification = _lastNotificationTimes[ride.id]!;
        print('[LOCATION-SERVICE] Previous warning sent at: $lastNotification');
      }
    } else {
      print('[LOCATION-SERVICE] User is within allowed radius');
    }

    print('[LOCATION-SERVICE] Completed distance check for ride: ${ride.name}');
  }

  // Stop tracking and clean up resources
  Future<void> dispose() async {
    await _locationSubscription?.cancel();
    await _locationController.close();
    _isInitialized = false;
    _lastKnownPosition = null;
    _lastNotificationTimes.clear();
  }
}
