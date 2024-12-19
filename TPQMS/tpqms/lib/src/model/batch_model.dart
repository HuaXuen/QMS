class BatchModel {
  final String id; // Unique batch ID (Firebase push ID)
  final String rideId; // Ride ID associated with this batch
  final List<String> queueIds; // List of user IDs in the batch
  final String batchStatus; // Batch status: pending, in-progress, completed
  final int createdAt; // Timestamp in milliseconds since epoch
  final int? completedAt; // Nullable: Timestamp when the batch was completed
  final int? timeTakenToComplete; // Time in milliseconds to complete the batch

  BatchModel({
    required this.id,
    required this.rideId,
    required this.queueIds,
    required this.batchStatus,
    required this.createdAt,
    this.completedAt,
    this.timeTakenToComplete,
  });

  // Convert createdAt to DateTime
  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  // Convert completedAt to DateTime (if not null)
  DateTime? get completedAtDateTime => completedAt != null
      ? DateTime.fromMillisecondsSinceEpoch(completedAt!)
      : null;

  // Convert timeTakenToComplete to a readable duration (if not null)
  Duration? get timeTakenDuration => timeTakenToComplete != null
      ? Duration(milliseconds: timeTakenToComplete!)
      : null;

  @override
  String toString() {
    return 'BatchModel(id: $id, rideId: $rideId, queueIds: $queueIds, status: $batchStatus, '
        'createdAt: $createdAt, completedAt: $completedAt, timeTakenToComplete: $timeTakenToComplete)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'queueIds': queueIds,
      'status': batchStatus,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'timeTakenToComplete': timeTakenToComplete,
    };
  }

  factory BatchModel.fromMap(String id, Map<String, dynamic> map) {
    return BatchModel(
      id: id,
      rideId: map['rideId'] ?? '',
      queueIds: List<String>.from(map['queueIds'] ?? []),
      batchStatus: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? 0,
      completedAt: map['completedAt'],
      timeTakenToComplete: map['timeTakenToComplete'],
    );
  }
}
