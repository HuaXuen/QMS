// queue_management_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/providers/admin_providers/admin_ride_provider.dart';
import 'package:intl/intl.dart';

// A dialog that shows the current batch's queue and allows admins to manage it
class QueueManagementDialog extends StatelessWidget {
  final RideModel ride;
  final String adminId;

  const QueueManagementDialog({
    Key? key,
    required this.ride,
    required this.adminId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<BatchModel>>(
                stream: context
                    .read<AdminRideProvider>()
                    .streamQueueManagementBatches(ride.id),
                builder: (context, snapshot) {
                  print('\n[QUEUE-DIALOG] Building with snapshot:');
                  print('  Connection state: ${snapshot.connectionState}');
                  print('  Has error: ${snapshot.hasError}');
                  print('  Has data: ${snapshot.hasData}');

                  if (snapshot.hasData) {
                    print('  Number of batches: ${snapshot.data?.length}');
                    snapshot.data?.forEach((batch) {
                      final startTime = DateTime.fromMillisecondsSinceEpoch(
                          batch.startAt,
                          isUtc: true);
                      print('  Batch: ${batch.id} starts at $startTime');
                    });
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final batches = snapshot.data ?? [];
                  if (batches.isEmpty) {
                    return const Center(child: Text('No active batches'));
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return _BatchCard(
                        batch: batch,
                        ride: ride,
                        adminId: adminId,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  // Keep existing _buildHeader() method unchanged
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Queue Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Constants.purple,
                ),
              ),
              Text(
                ride.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Will be implemented when we add admin providers
          },
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// New widget for individual batch cards
class _BatchCard extends StatelessWidget {
  final BatchModel batch;
  final RideModel ride;
  final String adminId;

  const _BatchCard({
    Key? key,
    required this.batch,
    required this.ride,
    required this.adminId,
  }) : super(key: key);

  bool get isPastBatch {
    final now = DateTime.now();
    final nowUtc = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );

    final batchEndTime =
        DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

    print('[BATCH-CHECK] Current time (UTC): $nowUtc');
    print('[BATCH-CHECK] Batch end time (UTC): $batchEndTime');
    print('[BATCH-CHECK] Is past batch: ${batchEndTime.isBefore(nowUtc)}');

    return batchEndTime.isBefore(nowUtc);
  }

  void _handleCompleteBatch(BuildContext context) {
    // Special warning dialog for past batches
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Past Batch'),
        content: Text('Are you sure you want to complete this past batch?\n\n'
            'Time: ${DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true))} - '
            '${DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true))}'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<AdminRideProvider>().completeBatch(
                      rideId: ride.id,
                      batchId: batch.id,
                      adminId: adminId,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Past batch completed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to complete batch: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child:
                const Text('Complete', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
    final timeFormat = DateFormat('hh:mm a');
    final queueIds = batch.queueIds.where((id) => id != 'empty').toList();
    final isCompleted = batch.batchStatus == 'completed';

    print(
        '[BATCH-CARD] Building batch ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}');
    print('[BATCH-CARD] Is past batch: $isPastBatch');
    print('[BATCH-CARD] Is completed: $isCompleted');
    print('[BATCH-CARD] Batch status: ${batch.batchStatus}');
    print(
        '[BATCH-CARD] Should show complete button: ${isPastBatch && !isCompleted}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[200] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isCompleted ? Colors.grey[400]! : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isPastBatch || isCompleted)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey[400] : Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Past Batch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (!isCompleted && isPastBatch)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minHeight: 30,
                          minWidth: 30,
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 20,
                        ),
                        onPressed: () => _handleCompleteBatch(context),
                        tooltip: 'Complete batch',
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.group, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${queueIds.length} / ${ride.numOfRidersAllowed} visitors',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (queueIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queueIds.length,
              itemBuilder: (context, index) {
                return _QueueItemCard(
                  userId: queueIds[index],
                  index: index + 1,
                  onDequeue: isCompleted
                      ? null
                      : () => _confirmDequeue(context, queueIds[index]),
                  ride: ride,
                  batch: batch,
                  adminId: adminId,
                  showActions: !isCompleted,
                  isPastBatch: isPastBatch,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDequeue(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Dequeue'),
        content: const Text(
            'Are you sure you want to remove this visitor from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminRideProvider>().dequeueVisitor(
                    rideId: ride.id,
                    batchId: batch.id,
                    visitorId: userId,
                    adminId: adminId,
                    reason: 'Admin initiated removal',
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// Keep existing _QueueItemCard widget unchanged

class _QueueItemCard extends StatelessWidget {
  final String userId;
  final int index;
  final VoidCallback? onDequeue;
  final RideModel ride;
  final BatchModel batch;
  final String adminId;
  final bool showActions; // Add new parameter
  final bool isPastBatch; // Add new parameter
  const _QueueItemCard(
      {Key? key,
      required this.userId,
      required this.index,
      required this.onDequeue,
      required this.ride,
      required this.batch,
      required this.adminId,
      this.showActions = true, // Default to true for backwards compatibility
      this.isPastBatch = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Leading number circle
            CircleAvatar(
              backgroundColor: Constants.purple,
              radius: 16,
              child: Text(
                index.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),

            // Visitor ID section with vertical layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Visitor ID:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                      height: 4), // Small spacing between label and value
                  Text(
                    userId,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action buttons column with fixed width
            if (showActions) ...[
              SizedBox(
                width: 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onDequeue != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minHeight: 30,
                          minWidth: 30,
                        ),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: onDequeue,
                        tooltip: 'Remove from queue',
                      ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 30,
                        minWidth: 30,
                      ),
                      icon: const Icon(
                        Icons.help_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      onPressed: () => _handleMarkAsMissed(context),
                      tooltip: 'Mark as missed queue',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMarkAsMissed(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Missed Queue'),
        content: Text(
            'Are you sure you want to mark this visitor as missed for this queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminRideProvider>().markVisitorAsMissed(
                    rideId: ride.id,
                    batchId: batch.id,
                    visitorId: userId,
                    adminId: adminId,
                    reason: 'Visitor marked as missed by admin',
                  );
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
