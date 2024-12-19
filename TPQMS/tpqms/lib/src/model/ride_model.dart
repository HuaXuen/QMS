class RideModel {
  final String name;
  final String category;
  final String status;
  final int heightRequirement;
  final int queueTime;
  final int numOfRidersAllowed;
  final String currentBatchId;

  RideModel({
    required this.name,
    required this.category,
    required this.status,
    required this.heightRequirement,
    required this.queueTime,
    required this.numOfRidersAllowed,
    required this.currentBatchId,
  });
  @override
  String toString() {
    return 'RideModel(name: $name, category: $category, status: $status, heightRequirement: $heightRequirement, queueTime: $queueTime)';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'status': status,
      'heightRequirement': heightRequirement,
      'queueTime': queueTime,
      'numOfRidersAllowed': numOfRidersAllowed,
    };
  }

  factory RideModel.fromMap(String id, Map<String, dynamic> map) {
    return RideModel(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      heightRequirement: map['heightRequirement'] ?? 0,
      queueTime: map['queueTime'] ?? 0,
      numOfRidersAllowed: map['numOfRidersAllowed'] ?? 0,
      currentBatchId: map['currentBatchId'] ?? '',
    );
  }
}
