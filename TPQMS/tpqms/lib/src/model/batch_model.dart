class BatchModel {
  final String id;
  final int startAt; // Timestamp in milliseconds
  final int endAt; // Timestamp in milliseconds
  final String batchStatus;
  final int completedAt;
  final List<String> queueIds;
  final String queueFilledAt;

  BatchModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.batchStatus,
    required this.completedAt,
    required this.queueIds,
    required this.queueFilledAt,
  });

  @override
  String toString() {
    return 'BatchModel(id: $id, startAt: $startAt, endAt: $endAt)';
  }

  factory BatchModel.fromMap(String id, Map<String, dynamic> map) {
    return BatchModel(
      id: id,
      startAt: map['startAt'] ?? 0, // Remove assertion, use default
      endAt: map['endAt'] ?? 0, // Remove assertion, use default
      batchStatus: map['batchStatus'] ?? 'pending',
      queueIds: List<String>.from(map['queueIds'] ?? ['empty']),
      queueFilledAt: map['queueFilledAt'] ?? 'Not Filled Up',
      completedAt: map['completedAt'] ?? 0,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'startAt': startAt,
      'endAt': endAt,
      'batchStatus': batchStatus,
      'completedAt': completedAt,
      'queueIds': queueIds,
      'queueFilledAt': queueFilledAt,
    };
  }
}
