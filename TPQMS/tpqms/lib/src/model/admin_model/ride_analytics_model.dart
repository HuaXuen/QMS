// ride_analytics_model.dart

// Model for individual batch status entries in the statusList array
import 'package:intl/intl.dart';

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

  // Add to BatchStatusEntry:
  String get formattedBatchTime {
    // Convert batchKey (2025-01-03T10-00-00) to readable format
    final dateTime = DateTime.parse(batchKey.replaceAll('-', ':'));
    return DateFormat('hh:mm a').format(dateTime);
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
  final int createdAt;

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
    required this.createdAt, // Add this
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
      createdAt: reportData['createdAt'] ?? 0, // Add this
    );
  }

  // Formatted getters for timestamps
  String get formattedCreatedAt {
    final date =
        DateTime.fromMillisecondsSinceEpoch(int.parse(createdAt.toString()));
    return DateFormat('MMM dd, yyyy, hh:mm a').format(date);
  }

  String get formattedTimeOfReport {
    try {
      // Check if the timeOfReportGeneration is already in the formatted style
      if (timeOfReportGeneration.contains(',')) {
        // It's already formatted, just return it
        return timeOfReportGeneration;
      }

      // Otherwise, try to parse it as a standard datetime and format it
      final dateTime = DateTime.parse(timeOfReportGeneration);
      return DateFormat('MMM dd, yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting report time: $timeOfReportGeneration');
      print('Error details: $e');
      // Return the original string if parsing fails
      return timeOfReportGeneration;
    }
  }

  String formatBatchTime(String batchDateTime) {
    try {
      // First, split the date and time parts
      final parts = batchDateTime.split('T');
      if (parts.length != 2) {
        return batchDateTime; // Return original if format is unexpected
      }

      // Keep the date part as is (with hyphens)
      final datePart = parts[0];
      // Replace hyphens with colons only in the time part
      final timePart = parts[1].replaceAll('-', ':');

      // Combine them back with a space
      final formattedDateTime = '$datePart $timePart';

      // Parse and format
      final dateTime = DateTime.parse(formattedDateTime);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting batch time: $batchDateTime');
      print('Error details: $e');
      return batchDateTime; // Return original string if parsing fails
    }
  }
}
