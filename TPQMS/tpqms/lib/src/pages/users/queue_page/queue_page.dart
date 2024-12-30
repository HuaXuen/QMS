import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/main_page_wrapper.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainPageWrapper(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: CustomAppBar(
          title: 'My Queue Status',
          backgroundColor: Constants.purple,
        ),
        body: Consumer<QueueProvider>(
          builder: (context, queueProvider, child) {
            if (queueProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final queues = queueProvider.currentQueues;

            if (queues.isEmpty) {
              return const Center(
                child: Text(
                  'You are not in any queue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queues.length,
              itemBuilder: (context, index) {
                final queue = queues[index];
                return QueuedRideCard(
                  rideName: queue.rideName,
                  waitTime: '${queue.waitTime} minutes',
                  batchTime: _formatBatchTime(queue.startAt, queue.endAt),
                  onDequeue: () async {
                    await queueProvider.dequeueFromRide(
                      rideId: queue.rideId,
                      batchId: queue.batchId,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatBatchTime(int startAt, int endAt) {
    final start = DateTime.fromMillisecondsSinceEpoch(startAt, isUtc: true);
    final end = DateTime.fromMillisecondsSinceEpoch(endAt, isUtc: true);
    return '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';
  }
}

class QueuedRideCard extends StatelessWidget {
  final String rideName;
  final String waitTime;
  final String batchTime; // Added this field
  final VoidCallback onDequeue;

  const QueuedRideCard({
    Key? key,
    required this.rideName,
    required this.waitTime,
    required this.batchTime,
    required this.onDequeue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rideName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Wait time row
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Constants.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Wait time: $waitTime',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Batch time row
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Constants.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    batchTime,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDequeue,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Leave Queue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
