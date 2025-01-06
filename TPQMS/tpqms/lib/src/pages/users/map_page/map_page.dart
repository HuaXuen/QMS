// map_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/main_page_wrapper.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/src/providers/user_providers/location_provider.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  //Set<Polyline> _polylines = {};
  Timer? _updateTimer;
  Map<String, Polyline> _polylines = {};
  final String _googleAPIKey =
      "AIzaSyBgU-SDaZM8B5D3OOcb5KITsBW05TBMXVk"; // Use your existing API key
  poly.PolylinePoints polylinePoints = poly.PolylinePoints();

  // Add this method to get walking directions
  Future<void> _getDirections(
      LatLng origin, LatLng destination, String rideId) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=walking'
          '&key=$_googleAPIKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded['routes'].isEmpty) {
          print('[MAP] No routes found');
          return;
        }

        final points = polylinePoints.decodePolyline(
            decoded['routes'][0]['overview_polyline']['points']);

        final List<LatLng> polylineCoordinates = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        final polyline = Polyline(
          polylineId: PolylineId('route_$rideId'),
          color: Constants.purple,
          points: polylineCoordinates,
          width: 4,
        );

        // Update only this specific route without clearing others
        setState(() {
          _polylines[rideId] = polyline;
        });
      }
    } catch (e) {
      print('[MAP] Error getting directions: $e');
    }
  }

  // Initial camera position (you can set this to your theme park's location)
  static const _initialPosition = CameraPosition(
    target: LatLng(3.055905348421602, 101.70002312314254), //apu coords
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeLocationTracking();
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        final queueProvider = context.read<QueueProvider>();
        final locationProvider = context.read<LocationProvider>();
        final rideProvider = context.read<RideProvider>(); // Add this line

        // Update distances for queued rides
        final queuedRides = queueProvider.currentQueues
            .map((queue) => rideProvider.rides
                .firstWhere((ride) => ride.id == queue.rideId))
            .toList();

        locationProvider.getDistanceBetweenUserAndQueuedRides(queuedRides);

        _updateMarkers(context);
      }
    });
  }

  Future<void> _initializeLocationTracking() async {
    final locationProvider = context.read<LocationProvider>();
    if (!locationProvider.isInitialized) {
      await locationProvider.initialize();
    }
    if (!locationProvider.isTracking) {
      await locationProvider.startTracking();
    }
    _updateMarkers(context);
  }

  void _updateMarkers(BuildContext context) {
    print('[MAP] Updating markers...');
    final rideProvider = context.read<RideProvider>();
    final queueProvider = context.read<QueueProvider>();
    final locationProvider = context.read<LocationProvider>();

    final rides = rideProvider.rides;
    final queuedRides = queueProvider.currentQueues;

    print(
        '[MAP] Processing ${rides.length} rides and ${queuedRides.length} queued rides');

    // Create a temporary set of markers
    Set<Marker> newMarkers = {};

    // Update markers without affecting polylines
    setState(() {
      // Clear only markers, not polylines
      _markers = newMarkers;

      // Add markers for all rides
      for (final ride in rides) {
        if (ride.latitude != null && ride.longitude != null) {
          print(
              '[MAP] Adding marker for ride: ${ride.name} at (${ride.latitude}, ${ride.longitude})');
          final isQueued = queuedRides.any((queue) => queue.rideId == ride.id);

          // Calculate and format distance for queued rides
          String snippetText = ride.status;
          if (isQueued && locationProvider.currentPosition != null) {
            final distance = locationProvider.getDistanceToRide(ride.id);
            if (distance != null) {
              snippetText =
                  'Queued - ${distance.toStringAsFixed(2)} meters away - ${ride.status}';
            }
          }

          _markers.add(
            Marker(
              markerId: MarkerId(ride.id),
              position: LatLng(ride.latitude!, ride.longitude!),
              infoWindow: InfoWindow(
                title: ride.name,
                snippet: snippetText,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                isQueued ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
      }

      // Add user location marker if available
      if (locationProvider.currentPosition != null) {
        print('[MAP] Adding user location marker');
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(
              locationProvider.currentPosition!.latitude,
              locationProvider.currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
          ),
        );
      }
    });

    // Update routes without clearing existing ones
    if (locationProvider.currentPosition != null) {
      for (final ride in rides) {
        if (ride.latitude != null &&
            ride.longitude != null &&
            queuedRides.any((queue) => queue.rideId == ride.id)) {
          final origin = LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          );
          final destination = LatLng(ride.latitude!, ride.longitude!);

          // Get walking directions - polylines will be updated individually
          _getDirections(origin, destination, ride.id);
        } else {
          // Remove polyline for unqueued rides
          if (_polylines.containsKey(ride.id)) {
            setState(() {
              _polylines.remove(ride.id);
            });
          }
        }
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh markers whenever dependencies change (e.g., ride or queue data updates)
    _updateMarkers(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateMarkers(context);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _centerOnUser() async {
    final locationProvider = context.read<LocationProvider>();
    final position = locationProvider.currentPosition;

    if (position != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainPageWrapper(
      currentIndex: 3, // Assuming map is the fourth item
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: const CustomAppBar(
          title: 'Theme Park Map',
          backgroundColor: Constants.purple,
        ),
        body: Consumer3<LocationProvider, RideProvider, QueueProvider>(
          builder: (context, locationProvider, rideProvider, queueProvider, _) {
            // Show error if location services initialization failed
            if (locationProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Location Error: ${locationProvider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _initializeLocationTracking,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Show loading indicator while initializing
            if (!locationProvider.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Build the map
            return Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  polylines: Set<Polyline>.of(_polylines.values),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                // Location centering button
                Positioned(
                  right: 2,
                  bottom: MediaQuery.of(context).padding.bottom +
                      110, // Add padding for navigation bar
                  child: FloatingActionButton(
                    onPressed: _centerOnUser,
                    backgroundColor: Constants.grey,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
