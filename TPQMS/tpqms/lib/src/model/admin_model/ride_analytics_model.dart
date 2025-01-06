// ride_analytics_model.dart

// Model for individual batch status entries in the statusList array
class BatchStatusEntry {
  final String batchKey; // Format: "2025-01-01T13..."
  final String? completedBy; // Admin ID who completed the batch (can be null)
  final String status; // Batch status (e.g., "pending")

  BatchStatusEntry({
    required this.batchKey,
    this.completedBy,
    required this.status,
  });

  factory BatchStatusEntry.fromMap(Map<String, dynamic> map) {
    return BatchStatusEntry(
      batchKey: map['batchKey'] ?? '',
      completedBy: map['completedBy'],
      status: map['status'] ?? 'unknown',
    );
  }
}

// Model for the batchStatusSummary object
class BatchStatusSummary {
  final int completed;
  final int failed;
  final int other;
  final int pending;
  final List<BatchStatusEntry> statusList;

  BatchStatusSummary({
    required this.completed,
    required this.failed,
    required this.other,
    required this.pending,
    required this.statusList,
  });

  factory BatchStatusSummary.fromMap(Map<String, dynamic> map) {
    // Handle the statusList array
    List<BatchStatusEntry> statusEntries = [];
    if (map['statusList'] != null) {
      statusEntries = (map['statusList'] as List)
          .map((entry) =>
              BatchStatusEntry.fromMap(entry as Map<String, dynamic>))
          .toList();
    }

    return BatchStatusSummary(
      completed: map['completed'] ?? 0,
      failed: map['failed'] ?? 0,
      other: map['other'] ?? 0,
      pending: map['pending'] ?? 0,
      statusList: statusEntries,
    );
  }

  int get totalBatches => completed + failed + other + pending;
}

// Main analytics model for a ride report
class RideAnalyticsModel {
  final String rideName; // From document ID
  final String reportDate; // From document ID
  final String averageQueueTime; // Can be "N/A"
  final BatchStatusSummary batchStatusSummary;
  final String busiestBatchStartTime; // Can be "N/A"
  final String? fastestCompletionTime; // Can be null
  final int nonCompletedBatchCount;
  final List<String> nonCompletedBatchTimes;
  final int nonFilledBatchCount;
  final List<String> nonFilledBatchIds;
  final List<String> operators; // Array of operator IDs
  final String rideStatus;
  final String timeOfReportGeneration;
  final int totalVisitors;

  RideAnalyticsModel({
    required this.rideName,
    required this.reportDate,
    required this.averageQueueTime,
    required this.batchStatusSummary,
    required this.busiestBatchStartTime,
    required this.fastestCompletionTime,
    required this.nonCompletedBatchCount,
    required this.nonCompletedBatchTimes,
    required this.nonFilledBatchCount,
    required this.nonFilledBatchIds,
    required this.operators,
    required this.rideStatus,
    required this.timeOfReportGeneration,
    required this.totalVisitors,
  });

  factory RideAnalyticsModel.fromDocument(
      String documentId, Map<String, dynamic> data) {
    // Extract ride name and date from document ID (format: "rideName_YYYY-MM-DD")
    final parts = documentId.split('_');
    final rideName = parts
        .take(parts.length - 1)
        .join('_'); // Handle ride names with underscores
    final reportDate = parts.last;

    // Get the data for the specific date
    final reportData = data[reportDate] as Map<String, dynamic>;

    return RideAnalyticsModel(
      rideName: rideName,
      reportDate: reportDate,
      averageQueueTime: reportData['averageQueueTime'] ?? 'N/A',
      batchStatusSummary: BatchStatusSummary.fromMap(
        reportData['batchStatusSummary'] as Map<String, dynamic>? ?? {},
      ),
      busiestBatchStartTime: reportData['busiestBatchStartTime'] ?? 'N/A',
      fastestCompletionTime: reportData['fastestCompletionTime'],
      nonCompletedBatchCount: reportData['nonCompletedBatchCount'] ?? 0,
      nonCompletedBatchTimes:
          List<String>.from(reportData['nonCompletedBatchTimes'] ?? []),
      nonFilledBatchCount: reportData['nonFilledBatchCount'] ?? 0,
      nonFilledBatchIds:
          List<String>.from(reportData['nonFilledBatchIds'] ?? []),
      operators: List<String>.from(reportData['operators'] ?? []),
      rideStatus: reportData['rideStatus'] ?? 'unknown',
      timeOfReportGeneration: reportData['timeOfReportGeneration'] ?? '',
      totalVisitors: reportData['totalVisitors'] ?? 0,
    );
  }
}
