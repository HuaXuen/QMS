import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';

class RideService {
  final RealtimeDbService _dbService;

  RideService(this._dbService);
  FirebaseFunctions functions = FirebaseFunctions.instance;
  // Stream rides data along with batches
  Stream<List<RideModel>> streamRidesWithBatches() {
    return _dbService
        .streamData(Constants.ridesDbRoute)
        .asyncMap((event) async {
      if (event.snapshot.value == null) return [];

      try {
        final Map data = event.snapshot.value as Map;

        // Log the raw data for debugging
        //print('[RIDE-SERVICE] Raw data received: $data');

        final rides = data.entries.map<RideModel>((entry) {
          // Log each ride's data before transformation
          //print('[RIDE-SERVICE] Processing ride ${entry.key}: ${entry.value}');

          final rideMap = Map<String, dynamic>.from(entry.value as Map);
          return RideModel.fromMap(entry.key as String, rideMap);
        }).toList();

        // Fetch batches with error handling
        for (var ride in rides) {
          try {
            final batches = await _fetchBatchesForRide(ride.id);
            ride.batches = batches;
          } catch (e) {
            print(
                '[RIDE-SERVICE] Error fetching batches for ride ${ride.id}: $e');
            // Continue with other rides even if one fails
          }
        }

        return rides;
      } catch (e) {
        print('[RIDE-SERVICE] Error processing rides: $e');
        return []; // Return empty list instead of throwing
      }
    });
  }

  // Fetch batches for a specific ride
  Future<List<BatchModel>> _fetchBatchesForRide(String rideId) async {
    final batchPath = '${Constants.ridesDbRoute}/$rideId/batches';
    final batchData = await _dbService.read(batchPath);

    if (batchData == null) return [];

    try {
      final Map data = batchData as Map;
      return data.entries.map<BatchModel>((entry) {
        return BatchModel.fromMap(
          entry.key as String,
          Map.from(entry.value as Map),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing batches for ride $rideId: $e');
      return [];
    }
  }

  // Add a batch for a ride
  Future<void> addBatch(String rideId, BatchModel batch) async {
    final batchPath = '${Constants.ridesDbRoute}/$rideId/batches/${batch.id}';
    try {
      await _dbService.create(batchPath, batch.toMap());
    } catch (e) {
      debugPrint('Error adding batch for ride $rideId: $e');
      rethrow;
    }
  }

  Future<RideModel?> getRideById(String rideId) async {
    try {
      final data = await _dbService.read('rides/$rideId');
      if (data != null) {
        return RideModel.fromMap(rideId, Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      print('Error getting ride by ID: $e');
      return null;
    }
  }

  // Get batches for a ride
  Future<List<BatchModel>> getBatches(String rideId) async {
    return await _fetchBatchesForRide(rideId);
  }

  Future<BatchModel> getBatchById(String rideId, String batchId) async {
    try {
      final data = await _dbService.read('rides/$rideId/batches/$batchId');
      if (data != null) {
        return BatchModel.fromMap(batchId, Map<String, dynamic>.from(data));
      }
      throw Exception('Batch not found for notification');
    } catch (e) {
      print('Error getting batch by ID: $e');
      throw Exception('Failed to get batch: $e');
    }
  }

  // Stream batches for a ride
  Stream<List<BatchModel>> streamBatches(String rideId) {
    final batchPath = '${Constants.ridesDbRoute}/$rideId/batches';
    return _dbService.streamData(batchPath).map((DatabaseEvent event) {
      if (event.snapshot.value == null) return [];

      try {
        final Map data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return BatchModel.fromMap(
            entry.key as String,
            Map.from(entry.value as Map),
          );
        }).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
      } catch (e) {
        debugPrint('Error parsing batches for ride $rideId: $e');
        return [];
      }
    });
  }

  Future<String?> addRide(
      {required String name,
      required String category,
      required String status,
      required int heightRequirement,
      required int queueTime,
      required int numOfRidersAllowed,
      required DateTime createdAt,
      required double latitude,
      required double longitude,
      required double radiusInMeters}) async {
    try {
      // Step 1: Prepare the ride data
      final newRide = {
        'name': name,
        'category': category,
        'status': status,
        'heightRequirement': heightRequirement,
        'queueTime': queueTime,
        'numOfRidersAllowed': numOfRidersAllowed,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'latitude': latitude,
        'longitude': longitude,
        'radiusInMeters': radiusInMeters,
      };

      // Log the prepared data
      print('Preparing to call Firebase function with data: $newRide');

      // Step 2: Call the Firebase Cloud Function
      try {
        print('Calling Firebase function: addRideAndBatchesFunc...');
        final callable =
            FirebaseFunctions.instanceFor(region: 'asia-southeast1')
                .httpsCallable('addRideAndBatchesFunc');
        final result = await callable.call(newRide);

        // Log the function response
        print('Firebase function response received: ${result.data}');

        // Extract and return the ride ID from the response
        final rideId = result.data['rideId'];
        print('Ride created successfully with ID: $rideId');
        return rideId;
      } on FirebaseFunctionsException catch (error) {
        // Log Firebase-specific errors
        print('FirebaseFunctionsException occurred:');
        print('Error code: ${error.code}');
        print('Error details: ${error.details}');
        print('Error message: ${error.message}');
        return null;
      }
    } catch (e) {
      // Log any other errors
      print('An unexpected error occurred in addRide: $e');
      return null;
    }
  }

  Future<String?> getStatusFromId(String rideId) async {
    try {
      //fetch all ride data from the database
      final data = await _dbService.read(Constants.ridesDbRoute);
      //check if data exists and contains the specific rideId
      if (data != null && data.containsKey(rideId)) {
        final rideData = data[rideId];
        //check if 'status' exists in the ride's data
        if (rideData.containsKey('status')) {
          return rideData['status'] as String; // Return the status value
        }
      }
      return null; // Return null if rideId or status is not found
    } catch (e) {
      debugPrint('Error getting ride status: $e');
      return null; // Handle exceptions gracefully
    }
  }

  Future<void> updateRideStatus(String rideId, String newStatus) async {
    try {
      // Build the path to the specific ride document's status field
      String path = '${Constants.ridesDbRoute}/$rideId';

      // Update only the 'status' field without overwriting other data
      await _dbService.update(path, {'status': newStatus});

      debugPrint('Ride status updated successfully to: $newStatus');
    } catch (e) {
      debugPrint('Error updating ride status: $e');
      rethrow; // Propagate the error for debugging
    }
  }

  Future<void> deleteRide(String rideId) async {
    try {
      await _dbService.delete('${Constants.ridesDbRoute}/$rideId');
    } catch (e) {
      debugPrint('Error deleting ride: $e');
      rethrow;
    }
  }
}
