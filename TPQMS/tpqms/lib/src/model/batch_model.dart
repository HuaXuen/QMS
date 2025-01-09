class BatchModel {
  final String id;
  final int startAt; // Timestamp in milliseconds
  final int endAt; // Timestamp in milliseconds
  final String batchStatus;
  final int completedAt;
  final List<String> queueIds;
  final String queueFilledAt;
  final int? notificationId;
  // Add a computed property for deterministic notification ID
  int get deterministicNotificationId {
    // Combine batch ID components to create a unique, consistent hash
    final idComponents = id.split('T'); // Splits like "2025-01-02T15-10-00"
    final dateStr = idComponents[0].replaceAll('-', ''); // "20250102"
    final timeStr = idComponents[1].replaceAll('-', ''); // "151000"
    return '${dateStr}${timeStr}'.hashCode;
  }

  BatchModel({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.batchStatus,
    required this.completedAt,
    required this.queueIds,
    required this.queueFilledAt,
    this.notificationId,
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
      notificationId: map['notificationId'],
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
      'notificationId': notificationId,
    };
  }
}
