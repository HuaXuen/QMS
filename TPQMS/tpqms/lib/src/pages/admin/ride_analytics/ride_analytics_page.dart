// ride_analytics_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/admin_model/ride_analytics_model.dart';
import 'package:tpqms/src/pages/admin/shared/admin_page_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tpqms/src/providers/admin_providers/admin_ride_analytics_provider.dart';

class RideAnalyticsPage extends StatelessWidget {
  const RideAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdminPageWrapper(
      currentIndex: 2, // Analytics is the third tab
      child: Scaffold(
        backgroundColor: Constants.primaryBackground,
        appBar: AppBar(
          title: const Text(
            'Ride Analytics',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Constants.purple,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<RideAnalyticsProvider>().refresh();
              },
            ),
          ],
        ),
        body: const RideAnalyticsContent(),
      ),
    );
  }
}

class RideAnalyticsContent extends StatelessWidget {
  const RideAnalyticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RideAnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (provider.reports.isEmpty) {
          return const Center(
            child: Text(
              'No analytics reports available',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OverallMetricsCard(),
              const SizedBox(height: 24),
              const Text(
                'Recent Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                padding: EdgeInsets.fromLTRB(0, 16, 0, 60),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.reports.length,
                itemBuilder: (context, index) {
                  return AnalyticsReportCard(
                    report: provider.reports[index],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class OverallMetricsCard extends StatelessWidget {
  const OverallMetricsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metrics = context.select(
        (RideAnalyticsProvider provider) => provider.getOverallMetrics());

    return Card(
      color: Constants.purple.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.purple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn(
                  'Total Visitors',
                  '${metrics['totalVisitors']}',
                  Icons.people,
                ),
                _buildMetricColumn(
                  'Completion Rate',
                  '${metrics['completionRate'].toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
                _buildMetricColumn(
                  'Total Reports',
                  '${metrics['totalReports']}',
                  Icons.analytics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Constants.purple, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class AnalyticsReportCard extends StatelessWidget {
  final RideAnalyticsModel report;

  const AnalyticsReportCard({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Constants.purple.withOpacity(0.09),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          report.rideName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          report.reportDate,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Status', report.rideStatus),
                _buildDetailRow('Total Visitors', '${report.totalVisitors}'),
                _buildDetailRow('Average Queue Time', report.averageQueueTime),
                const SizedBox(height: 16),
                const Text(
                  'Batch Status Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBatchStatusChart(report.batchStatusSummary),
                if (report.nonCompletedBatchCount > 0) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Non-completed Batches: ${report.nonCompletedBatchCount}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchStatusChart(BatchStatusSummary summary) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            if (summary.completed > 0)
              PieChartSectionData(
                color: Colors.green,
                value: summary.completed.toDouble(),
                title: '${summary.completed}',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (summary.pending > 0)
              PieChartSectionData(
                color: Colors.blue,
                value: summary.pending.toDouble(),
                title: '${summary.pending}',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (summary.failed > 0)
              PieChartSectionData(
                color: Colors.red,
                value: summary.failed.toDouble(),
                title: '${summary.failed}',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (summary.other > 0)
              PieChartSectionData(
                color: Colors.grey,
                value: summary.other.toDouble(),
                title: '${summary.other}',
                radius: 50,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
