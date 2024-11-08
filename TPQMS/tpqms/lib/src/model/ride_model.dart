class RideModel {
  //final String id;
  final String name;
  final String category;
  final String status;
  final int heightRequirement;
  final int queueTime;

  RideModel({
    //required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.heightRequirement,
    required this.queueTime,
  });
  @override
  String toString() {
    return 'RideModel(name: $name, category: $category, status: $status, heightRequirement: $heightRequirement, queueTime: $queueTime)';
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,
      'name': name,
      'category': category,
      'status': status,
      'heightRequirement': heightRequirement,
      'queueTime': queueTime,
    };
  }

  factory RideModel.fromMap(String id, Map<String, dynamic> map) {
    return RideModel(
      //id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? '',
      heightRequirement: map['heightRequirement'] ?? 0,
      queueTime: map['queueTime'] ?? 0,
    );
  }
}
