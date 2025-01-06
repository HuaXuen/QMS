// queue_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/main_page_wrapper.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/src/model/queue_model.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';

class QueuePage extends StatefulWidget {
  // Change to StatefulWidget
  const QueuePage({Key? key}) : super(key: key);

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> with WidgetsBindingObserver {
  Timer? _refreshTimer; // Add timer for periodic updates

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Call onQueuePageOpened when page is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeQueueUpdates();
    });
  }

  void _initializeQueueUpdates() {
    final queueProvider = context.read<QueueProvider>();

    // Initial refresh
    queueProvider.onQueuePageOpened();

    // Set up periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        queueProvider.refreshQueueWaitTimes();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      _initializeQueueUpdates();
    }
  }

  @override
  void dispose() {
    // Clean up timer when page is disposed
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainPageWrapper(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: const CustomAppBar(
          title: 'My Queue Status',
          backgroundColor: Constants.purple,
        ),
        body: Consumer<QueueProvider>(
          builder: (context, queueProvider, _) {
            // Show loading state if needed
            if (queueProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter out completed queues and get active ones
            final activeQueues = queueProvider.currentQueues
                .where((queue) => queue.status != 'completed')
                .toList();

            // Show empty state if no active queues
            if (activeQueues.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.confirmation_num_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'You are not in any active queues',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Try queueing for a ride!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show active queues
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeQueues.length,
              itemBuilder: (context, index) {
                final queue = activeQueues[index];
                return QueuedRideCard(
                  queue: queue,
                  onDequeue: () =>
                      _handleDequeue(context, queueProvider, queue),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleDequeue(
    BuildContext context,
    QueueProvider queueProvider,
    QueueModel queue,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Queue'),
        content: Text(
          'Are you sure you want to leave the queue for ${queue.rideName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await queueProvider.dequeueFromRide(
                  rideId: queue.rideId,
                  batchId: queue.batchId,
                  context: context,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Left queue for ${queue.rideName}'),
                      backgroundColor: Constants.purple,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to leave queue: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Leave Queue'),
          ),
        ],
      ),
    );
  }
}

class QueuedRideCard extends StatelessWidget {
  final QueueModel queue;
  final VoidCallback onDequeue;

  const QueuedRideCard({
    Key? key,
    required this.queue,
    required this.onDequeue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final waitTimeText =
        queue.waitTime > 0 ? '${queue.waitTime} minutes' : 'Less than a minute';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
              queue.rideName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Wrap the wait time info in Expanded to prevent overflow
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Constants.purple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Wrap text in Expanded to handle long wait times
                      Expanded(
                        child: Text(
                          'Wait time: $waitTimeText',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Add spacing between elements
                // Make leave queue button more compact
                TextButton.icon(
                  onPressed: onDequeue,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: const Text(
                    'Leave',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
