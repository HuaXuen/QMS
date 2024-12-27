class BatchModel {
  final String id;
  final int startAt; // Timestamp in milliseconds
  final int endAt; // Timestamp in milliseconds
  final String batchStatus;
  final List<String> queueIds;
  final String queueFilledAt;

  BatchModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.batchStatus,
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
      startAt: map['startAt'] ?? 0,
      endAt: map['endAt'] ?? 0,
      batchStatus: map['batchStatus'] ?? 'pending',
      queueIds: List<String>.from(map['queueIds'] ?? []),
      queueFilledAt: map['queueFilledAt'] ?? 'Not Filled Up',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startAt': startAt,
      'endAt': endAt,
      'batchStatus': batchStatus,
      'queueIds': queueIds,
      'queueFilledAt': queueFilledAt,
    };
  }
}
