class QueueModel {
  final String userId;
  final String rideId;
  final String rideName;
  final String batchId;
  final int startAt; // Timestamp in milliseconds
  final int endAt; // Timestamp in milliseconds
  final int waitTime; // Wait time in minutes
  final String status; // e.g., 'waiting', 'completed', 'missed'

  QueueModel({
    required this.userId,
    required this.rideId,
    required this.rideName,
    required this.batchId,
    required this.startAt,
    required this.endAt,
    required this.waitTime,
    required this.status,
  });

  factory QueueModel.fromMap(Map<String, dynamic> map) {
    return QueueModel(
      userId: map['userId'] ?? '',
      rideId: map['rideId'] ?? '',
      rideName: map['rideName'] ?? '',
      batchId: map['batchId'] ?? '',
      startAt: map['startAt'] ?? 0,
      endAt: map['endAt'] ?? 0,
      waitTime: map['waitTime'] ?? 0,
      status: map['status'] ?? 'waiting',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rideId': rideId,
      'rideName': rideName,
      'batchId': batchId,
      'startAt': startAt,
      'endAt': endAt,
      'waitTime': waitTime,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'QueueModel(userId: $userId, rideId: $rideId, rideName: $rideName, batchId: $batchId, startAt: $startAt, endAt: $endAt, waitTime: $waitTime, status: $status)';
  }
}
