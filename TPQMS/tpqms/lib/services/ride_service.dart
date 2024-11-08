import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/services/realtimedb_service.dart';

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

  // CRUD Operations
  Future<void> createRide(RideModel ride) async {
    try {
      await _dbService.createWithAutoId(Constants.ridesDbRoute, ride.toMap());
    } catch (e) {
      debugPrint('Error adding ride: $e');
      rethrow;
    }
  }

  // Future<void> updateRide(RideModel ride) async {
  //   try {
  //     await _dbService.update(
  //         '${Constants.ridesDbRoute}/${ride.id}', ride.toMap());
  //   } catch (e) {
  //     debugPrint('Error updating ride: $e');
  //     rethrow;
  //   }
  // }

  Future<void> deleteRide(String rideId) async {
    try {
      await _dbService.delete('${Constants.ridesDbRoute}/$rideId');
    } catch (e) {
      debugPrint('Error deleting ride: $e');
      rethrow;
    }
  }
}
