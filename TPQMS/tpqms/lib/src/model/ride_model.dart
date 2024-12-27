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
    this.batches,
  });

  @override
  String toString() {
    return 'RideModel(id: $id, name: $name, category: $category, status: $status, heightRequirement: $heightRequirement, queueTime: $queueTime, numOfRidersAllowed: $numOfRidersAllowed, currentBatchId: $currentBatchId, createdAt: $createdAt, batches: $batches)';
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
      'batches': batches != null
          ? batches!.map((batch) => batch.toMap()).toList()
          : [],
    };
  }

  factory RideModel.fromMap(String id, Map<String, dynamic> map,
      [List<BatchModel>? batches]) {
    return RideModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      heightRequirement: map['heightRequirement'] ?? 0,
      queueTime: map['queueTime'] ?? 0,
      numOfRidersAllowed: map['numOfRidersAllowed'] ?? 0,
      currentBatchId: map['currentBatchId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      batches: batches,
    );
  }
}
