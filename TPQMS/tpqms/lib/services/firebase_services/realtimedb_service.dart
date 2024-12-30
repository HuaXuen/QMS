import 'package:firebase_database/firebase_database.dart';

class RealtimeDbService {
  final _firebaseRealDB = FirebaseDatabase.instance;

  // Create operation
  Future<void> create(String path, Map<String, dynamic> data) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      await ref.set(data);
    } catch (e) {
      throw Exception('Failed to create data: $e');
    }
  }

  // Create with auto-generated key
  Future<String> createWithAutoId(
      String path, Map<String, dynamic> data) async {
    try {
      print("Inside createWithAutoId");
      print("Path being used: $path");
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      print("Reference created");
      final newRef = ref.push();
      print("Push created");
      print("Data being set: ${data}");

      await newRef.set(data);

      print("Data set");
      return newRef.key ?? '';
    } catch (e) {
      throw Exception('Failed to create data with auto ID: $e');
    }
  }

  // Read operation
  // Future<Map<String, dynamic>?> read(String path) async {
  //   try {
  //     final DatabaseReference ref = _firebaseRealDB.ref(path);
  //     final snapshot = await ref.get();

  //     if (snapshot.exists) {
  //       return Map<String, dynamic>.from(snapshot.value as Map);
  //     }
  //     return null;
  //   } catch (e) {
  //     throw Exception('Failed to read data: $e');
  //   }
  // }

  Future<Map<String, dynamic>?> read(String path) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      final snapshot = await ref.get();

      //print("[DB-SERVICE] Raw snapshot value: ${snapshot.value}"); // Debug log

      if (snapshot.exists) {
        if (snapshot.value is Map) {
          // Convert all levels properly
          final converted = _convertToStringDynamicMap(snapshot.value as Map);
          //print("[DB-SERVICE] Converted data: $converted"); // Debug log
          return converted;
        }
        return null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to read data: $e');
    }
  }

// Helper method to properly convert nested maps
  Map<String, dynamic> _convertToStringDynamicMap(Map data) {
    return Map<String, dynamic>.fromEntries(
      data.entries.map((e) {
        var value = e.value;
        if (value is Map) {
          value = _convertToStringDynamicMap(value);
        }
        return MapEntry(e.key.toString(), value);
      }),
    );
  }

  // Read with query
  Future<List<Map<String, dynamic>>> readWhere({
    required String path,
    required String orderByChild,
    required dynamic equalTo,
  }) async {
    try {
      final Query query =
          _firebaseRealDB.ref(path).orderByChild(orderByChild).equalTo(equalTo);

      final snapshot = await query.get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> values =
            snapshot.value as Map<dynamic, dynamic>;

        return values.entries.map((entry) {
          return Map<String, dynamic>.from(entry.value as Map);
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to read data with query: $e');
    }
  }

  // Update operation
  Future<void> update(String path, Map<String, dynamic> data) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      await ref.update(data);
    } catch (e) {
      throw Exception('Failed to update data: $e');
    }
  }

  // Delete operation
  Future<void> delete(String path) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      await ref.remove();
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  // Stream data changes
  Stream<DatabaseEvent> streamData(String path) {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      return ref.onValue.map((event) {
        //print("[DB-SERVICE] Complete data received: ${event.snapshot.value}");
        return event;
      });
    } catch (e) {
      throw Exception('Failed to stream data: $e');
    }
  }

  // Stream data with query
  Stream<DatabaseEvent> streamWhere({
    required String path,
    required String orderByChild,
    required dynamic equalTo,
  }) {
    try {
      final Query query =
          _firebaseRealDB.ref(path).orderByChild(orderByChild).equalTo(equalTo);
      return query.onValue;
    } catch (e) {
      throw Exception('Failed to stream data with query: $e');
    }
  }

  // Transaction operation
  Future<void> runTransaction(
    String path,
    dynamic Function(dynamic value) transactionUpdate,
  ) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      await ref.runTransaction((Object? value) {
        return Transaction.success(transactionUpdate(value));
      });
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }

  // /// Updates multiple paths in the database atomically using a transaction
  // Future<void> runMultiPathTransaction({
  //   required Map<String, Map<String, dynamic>> updates,
  // }) async {
  //   try {
  //     final ref = _firebaseRealDB.ref();

  //     await ref.runTransaction((Object? data) {
  //       // Create a mutable transaction object
  //       final Transaction result = Transaction.success(data);

  //       // Apply each update
  //       updates.forEach((path, updateData) {
  //         ref.child(path).update(updateData);
  //       });

  //       return result;
  //     });
  //   } catch (e) {
  //     throw Exception('Failed to run multi-path transaction: $e');
  //   }
  // }

  Future<void> runMultiPathTransaction({
    required Map<String, dynamic> updates,
  }) async {
    try {
      final ref = _firebaseRealDB.ref();
      await ref.update(updates); // Perform atomic updates
      print('[DB-SERVICE] Successfully completed multi-path transaction');
    } catch (e) {
      print('[DB-SERVICE] Error in runMultiPathTransaction: $e');
      throw Exception('Failed to run multi-path transaction: $e');
    }
  }
}
