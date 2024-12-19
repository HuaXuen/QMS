import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';

class RideService {
  final RealtimeDbService _dbService;

  RideService(this._dbService);

  // Stream rides data
  Stream<List<RideModel>> streamRides() {
    return _dbService
        .streamData(Constants.ridesDbRoute)
        .map((DatabaseEvent event) {
      if (event.snapshot.value == null) return [];

      try {
        final Map data = event.snapshot.value as Map;
        print("snapshot success");

        return data.entries.map((entry) {
          return RideModel.fromMap(
            entry.key as String,
            Map.from(entry.value as Map),
          );
        }).toList();
      } catch (e) {
        debugPrint('Error parsing rides: $e');
        return [];
      }
    });
  }

  //generate timeslot batches (5 per hour)
  Future<void> generateTimeslots(String rideId, int numOfBatches) async {
    final now = DateTime.now(); // Start from the current time
    final Map<String, dynamic> slots = {};

    for (int i = 0; i < numOfBatches; i++) {
      final startAt = now.add(Duration(minutes: 20 * i));
      final endAt = startAt.add(Duration(minutes: 20));

      slots[startAt.toIso8601String()] = {
        'startAt': startAt.millisecondsSinceEpoch, // Convert to timestamp
        'endAt': endAt.millisecondsSinceEpoch,
        'queueIds': [],
        'status': 'pending',
      };
    }

    // Update Firebase with the generated timeslots
    await _dbService.update('rides/$rideId/batches', slots);
  }

  // CRUD Operations
  Future<void> createRide(RideModel ride) async {
    try {
      await _dbService.createWithAutoId(Constants.ridesDbRoute, ride.toMap());
    } catch (e) {
      debugPrint('Error adding ride: $e');
      rethrow;
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

  // Add a ride and return the auto-generated ID
  Future<String?> addRideWithAutoId(Map<String, dynamic> rideData) async {
    return await _dbService.createWithAutoId('rides', rideData);
  }

  Future<String> generateBatchId(String rideId) async {
    final batchRef = 'rides/$rideId/batches';
    return _dbService.createWithAutoId(batchRef, {});
  }

  // Step-by-step approach to add ride and batch
  Future<void> addRideAndBatch(String rideId, Map<String, dynamic> rideData,
      String batchId, Map<String, dynamic> batchData) async {
    try {
      // Step 1: Add Ride
      await _dbService.create('rides/$rideId', rideData);

      // Step 2: Add Batch
      await _dbService.create('rides/$rideId/batches/$batchId', batchData);

      // Step 3: Update currentBatchId
      await _dbService.update('rides/$rideId', {'currentBatchId': batchId});
    } catch (e) {
      throw Exception('Failed to add ride and batch: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentBatch(String rideId) async {
    final ridePath = 'rides/$rideId';
    final rideData = await _dbService.read(ridePath);

    if (rideData == null) {
      throw Exception('Ride not found.');
    }

    final currentBatchId = rideData['currentBatchId'];
    if (currentBatchId == null || currentBatchId.isEmpty) {
      throw Exception('No active batch found.');
    }

    final batchPath = 'rides/$rideId/batches/$currentBatchId';
    return await _dbService.read(batchPath);
  }

  Future<void> addToBatchQueue(
      String rideId, String batchId, String queueId) async {
    final batchPath = 'rides/$rideId/batches/$batchId';
    final batchData = await _dbService.read(batchPath);

    if (batchData == null) throw Exception('Batch not found.');

    List<dynamic> queueIds = batchData['queueIds'] ?? [];
    if (queueIds.contains(queueId)) {
      throw Exception('User already in the queue.');
    }

    queueIds.add(queueId);
    await _dbService.update(batchPath, {'queueIds': queueIds});
  }

  Future<String> createNewBatch(String rideId) async {
    final newBatchRef = 'rides/$rideId/batches';
    final batchId = await _dbService.createWithAutoId(newBatchRef, {
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'queueIds': [],
      'status': 'pending',
    });

    // Update currentBatchId in the ride
    final ridePath = 'rides/$rideId';
    await _dbService.update(ridePath, {'currentBatchId': batchId});
    return batchId;
  }

  Future<void> updateBatchQueue(
      String rideId, List<String> queueIdsToAdd) async {
    try {
      // Step 1: Fetch the current batch
      final currentBatch = await getCurrentBatch(rideId);

      if (currentBatch == null) throw Exception('No active batch found.');

      List<dynamic> queueIds = currentBatch['queueIds'] ?? [];
      final batchId = currentBatch['id'];

      // Step 2: Validate IDs
      queueIdsToAdd = queueIdsToAdd
          .where((id) =>
              id.isNotEmpty && !queueIds.contains(id)) // Filter out duplicates
          .toList();

      if (queueIdsToAdd.isEmpty) {
        throw Exception('No valid IDs to enqueue.');
      }

      // Step 3: Check batch capacity
      final maxCapacity = currentBatch['numOfRidersAllowed'] ?? 5;
      final remainingCapacity = maxCapacity - queueIds.length;

      if (remainingCapacity > 0) {
        // Add what fits into the current batch
        final toAdd = queueIdsToAdd.take(remainingCapacity).toList();
        queueIds.addAll(toAdd);

        // Update the current batch
        await _dbService.update(
          'rides/$rideId/batches/$batchId',
          {
            'queueIds': queueIds,
            'updatedAt':
                DateTime.now().millisecondsSinceEpoch, // Log enqueue time
          },
        );

        print('Added to current batch: $toAdd');
        queueIdsToAdd
            .removeWhere((id) => toAdd.contains(id)); // Remove added IDs
      }

      // Step 4: Handle overflow (create new batches)
      while (queueIdsToAdd.isNotEmpty) {
        final newBatchId = await createNewBatch(rideId);
        final toAdd = queueIdsToAdd.take(maxCapacity).toList();

        await _dbService.update(
          'rides/$rideId/batches/$newBatchId',
          {
            'queueIds': toAdd,
            'createdAt': DateTime.now().millisecondsSinceEpoch,
            'batchStatus': 'pending',
          },
        );

        print('Added to new batch $newBatchId: $toAdd');
        queueIdsToAdd
            .removeWhere((id) => toAdd.contains(id)); // Remove processed IDs
      }

      print('All users successfully enqueued.');
    } catch (e) {
      print('Error updating batch queue: $e');
      throw Exception('Failed to update batch queue: $e');
    }
  }
}
