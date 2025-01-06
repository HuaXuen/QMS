import 'package:tpqms/src/model/batch_model.dart';

class RideModel {
  final String id; // Key in the database
  final String name;
  final String category;
  final String status;
  final int heightRequirement;
  final int queueTime;
  final int numOfRidersAllowed;
  final String currentBatchId;
  final DateTime createdAt;
  final double? latitude; // Geofence center latitude
  final double? longitude; // Geofence center longitude
  final double? radiusInMeters; // Geofence radius in meters
  List<BatchModel>? batches;

  RideModel({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.heightRequirement,
    required this.queueTime,
    required this.numOfRidersAllowed,
    required this.currentBatchId,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.radiusInMeters,
    this.batches,
  });

  @override
  String toString() {
    return 'RideModel(id: $id, name: $name, category: $category, status: $status, heightRequirement: $heightRequirement, queueTime: $queueTime, numOfRidersAllowed: $numOfRidersAllowed, currentBatchId: $currentBatchId, createdAt: $createdAt)';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'status': status,
      'heightRequirement': heightRequirement,
      'queueTime': queueTime,
      'numOfRidersAllowed': numOfRidersAllowed,
      'currentBatchId': currentBatchId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'batches': batches != null
          ? batches!.map((batch) => batch.toMap()).toList()
          : [],
    };
  }

  factory RideModel.fromMap(String id, Map<String, dynamic> map,
      [List<BatchModel>? batches]) {
    print('[RIDE-MODEL] Creating RideModel from map: $map'); // Debug log

    // Validate required fields
    if (map['name'] == null || map['status'] == null) {
      print('[RIDE-MODEL] Warning: Required fields missing in map');
    }

    return RideModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      heightRequirement: _parseIntSafely(map['heightRequirement']),
      queueTime: _parseIntSafely(map['queueTime']),
      numOfRidersAllowed: _parseIntSafely(map['numOfRidersAllowed']),
      currentBatchId: map['currentBatchId'] ?? '',
      createdAt: _parseDateTimeSafely(map['createdAt']),
      latitude: _parseDoubleSafely(map['latitude']) ?? 0.0,
      longitude: _parseDoubleSafely(map['longitude']) ?? 0.0,
      radiusInMeters: _parseDoubleSafely(map['radiusInMeters']) ?? 100.0,
      batches: batches,
    );
  }

// Helper methods for safer parsing
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble(); // Convert int to double
    if (value is String) return double.tryParse(value);
    return null; // Default to null if parsing fails
  }

  static DateTime _parseDateTimeSafely(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
