import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/admin_model/ride_analytics_model.dart';

class RideAnalyticsProvider with ChangeNotifier {
  final FirestoreService _firestoreService;

  bool _isLoading = false;
  String? _error;
  List<RideAnalyticsModel> _reports = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<RideAnalyticsModel> get reports => _reports;

  RideAnalyticsProvider(this._firestoreService) {
    loadReports();
  }

  Future<void> loadReports() async {
    try {
      _setLoading(true);

      // Get all documents from rideAnalytics collection
      final QuerySnapshot querySnapshot =
          await _firestoreService.queryDocuments(
        'rideAnalytics',
        null,
      );

      _reports = querySnapshot.docs.map((doc) {
        // Document ID format: RideName_YYYY-MM-DD
        final String documentId = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        // Extract date from document ID to access the correct data
        final date = documentId.split('_').last;
        final analyticsData = data[date] as Map<String, dynamic>? ?? {};
        print('Document ID: $documentId');
        print('Extracted Date: $date');
        print('Raw Data for Date: ${data[date]}');

        return RideAnalyticsModel.fromDocument(
            documentId, {date: analyticsData});
      }).toList();

      // Sort by date in descending order
      _reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _handleError('Error loading analytics reports: $e');
    }
  }

  // Stream analytics data for real-time updates
  Stream<List<RideAnalyticsModel>> streamAnalytics() {
    return _firestoreService.getDocuments('rideAnalytics').map((snapshot) {
      final reports = snapshot.docs.map((doc) {
        final String documentId = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        // Extract date from document ID
        final date = documentId.split('_').last;
        final analyticsData = data[date] as Map<String, dynamic>? ?? {};

        return RideAnalyticsModel.fromDocument(
            documentId, {date: analyticsData});
      }).toList()
        ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

      return reports;
    });
  }

  // Calculate overall metrics across all reports
  Map<String, dynamic> getOverallMetrics() {
    if (_reports.isEmpty) {
      return {
        'totalVisitors': 0,
        'averageCompletionRate': 0.0,
        'averageFillRate': 0.0,
      };
    }

    int totalVisitors = 0;
    int totalCompletedBatches = 0;
    int totalBatches = 0;

    for (var report in _reports) {
      totalVisitors += report.totalVisitors;
      totalCompletedBatches += report.batchStatusSummary.completed;
      totalBatches += report.batchStatusSummary.totalBatches;
    }

    double completionRate =
        totalBatches > 0 ? (totalCompletedBatches / totalBatches) * 100 : 0.0;

    return {
      'totalVisitors': totalVisitors,
      'completionRate': completionRate,
      'totalReports': _reports.length,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  void _handleError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    print('RideAnalyticsProvider Error: $errorMessage');
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadReports();
  }
}
