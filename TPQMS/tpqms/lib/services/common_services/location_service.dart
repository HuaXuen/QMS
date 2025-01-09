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
  var _locationController = StreamController<Position>.broadcast();
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
      // Ensure we have a fresh controller
      if (_locationController.isClosed) {
        _locationController = StreamController<Position>.broadcast();
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _locationSubscription?.cancel(); // Cancel any existing subscription
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _lastKnownPosition = position;
        if (!_locationController.isClosed) {
          _locationController.add(position);
        }
      }, onError: (error) {
        debugPrint('Location stream error: $error');
        if (!_locationController.isClosed) {
          _locationController.addError(error);
        }
      });

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

      // Get the current time
      final now = DateTime.now();

      // Check if we should send a notification
      bool shouldNotify = false;

      if (!_lastNotificationTimes.containsKey(ride.id)) {
        // First time we're detecting the user is out of range
        shouldNotify = true;
        print(
            '[LOCATION-SERVICE] First time detection - will send notification');
      } else {
        // Calculate time since last notification
        final lastNotification = _lastNotificationTimes[ride.id]!;
        final timeSinceLastNotification = now.difference(lastNotification);

        // Check if 5 minutes have passed
        if (timeSinceLastNotification.inMinutes >= 5) {
          shouldNotify = true;
          print(
              '[LOCATION-SERVICE] 5 minutes passed since last notification (${timeSinceLastNotification.inMinutes} minutes) - will send notification');
        } else {
          print(
              '[LOCATION-SERVICE] Too soon for next notification. Minutes since last: ${timeSinceLastNotification.inMinutes}');
        }
      }

      // Send notification if conditions are met
      if (shouldNotify) {
        print('[LOCATION-SERVICE] Sending proximity warning notification');
        await _notificationService.sendDistanceWarningNotification(
            ride, distanceToPrint);
        _lastNotificationTimes[ride.id] = now;
        print(
            '[LOCATION-SERVICE] Warning notification sent and timestamp updated');
      }
    } else {
      print('[LOCATION-SERVICE] User is within allowed radius');
      // Optionally, clear the last notification time when user returns to allowed range
      // This will ensure they get a new notification immediately if they leave again
      if (_lastNotificationTimes.containsKey(ride.id)) {
        _lastNotificationTimes.remove(ride.id);
        print(
            '[LOCATION-SERVICE] Cleared notification history as user returned to allowed range');
      }
    }

    print('[LOCATION-SERVICE] Completed distance check for ride: ${ride.name}');
  }

  // Stop tracking and clean up resources
  Future<void> dispose() async {
    try {
      await _locationSubscription?.cancel();
      await _locationController.close();
      _isInitialized = false;
      _lastKnownPosition = null;
      _lastNotificationTimes.clear();
    } catch (e) {
      print('[LOCATION-SERVICE] Error during dispose: $e');
    }
  }
}
