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
  Future<Map<String, dynamic>?> read(String path) async {
    try {
      final DatabaseReference ref = _firebaseRealDB.ref(path);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to read data: $e');
    }
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
      return ref.onValue;
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
}
