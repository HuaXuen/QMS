// ride_analytics_detail_view.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/admin_model/ride_analytics_model.dart';

class RideAnalyticsDetailView extends StatelessWidget {
  final RideAnalyticsModel report;

  const RideAnalyticsDetailView({
    Key? key,
    required this.report,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.rideName),
        backgroundColor: Constants.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildBatchStatusSection(),
            const SizedBox(height: 24),
            _buildBatchDetailsSection(),
            const SizedBox(height: 24),
            _buildOperatorSection(),
            const SizedBox(height: 24),
            _buildTimeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.purple,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status', report.rideStatus),
            _buildInfoRow('Total Visitors', report.totalVisitors.toString()),
            _buildInfoRow('Average Queue Time', report.averageQueueTime),
            _buildInfoRow('Busiest Time', report.busiestBatchStartTime),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchStatusSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Batch Status Details'),
        children: [
          _buildPieChart(),
          _buildChartLegend(), // Add this

          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.batchStatusSummary.statusList.length,
            itemBuilder: (context, index) {
              final entry = report.batchStatusSummary.statusList[index];
              return ListTile(
                title: Text('Batch: ${report.formatBatchTime(entry.batchKey)}'),
                subtitle: Text('Status: ${entry.status}'),
                trailing: Text(entry.completedBy ?? 'Pending'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem('Completed', Colors.green),
          _buildLegendItem('Pending', Colors.blue),
          _buildLegendItem('Failed', Colors.red),
          _buildLegendItem('Other', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildBatchDetailsSection() {
    return Card(
      child: ExpansionTile(
        title: const Text('Batch Statistics'),
        children: [
          _buildExpandableList(
            'Non-Completed Batches (${report.nonCompletedBatchTimes.length})',
            report.nonCompletedBatchTimes,
          ),
          const Divider(),
          _buildExpandableList(
            'Non-Filled Batches (${report.nonFilledBatchCount})',
            report.nonFilledBatchIds
                .map((id) => report.formatBatchTime(id))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: report.operators
                  .map((op) => Chip(
                        label: Text(op),
                        backgroundColor: Constants.purple.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Created', report.formattedCreatedAt),
            _buildInfoRow('Report Generated', report.formattedTimeOfReport),
            if (report.fastestCompletionTime != null)
              _buildInfoRow(
                  'Fastest Completion', report.fastestCompletionTime!),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableList(String title, List<String> items) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Container(
          height: 200,
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(items[index]),
                leading: CircleAvatar(
                  backgroundColor: Constants.purple,
                  child: Text('${index + 1}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final summary = report.batchStatusSummary;
    final total = summary.totalBatches.toDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: [
            // Completed batches section (Green)
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
                titlePositionPercentageOffset: 0.6,
              ),

            // Pending batches section (Blue)
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
                titlePositionPercentageOffset: 0.6,
              ),

            // Failed batches section (Red)
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
                titlePositionPercentageOffset: 0.6,
              ),

            // Other batches section (Grey)
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
                titlePositionPercentageOffset: 0.6,
              ),
          ],
          // Add a legend at the bottom
          startDegreeOffset: -90,
        ),
      ),
    );
  }
}
