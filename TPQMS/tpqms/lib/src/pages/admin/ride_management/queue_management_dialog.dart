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
                    .streamCurrentHourBatches(ride.id),
                builder: (context, snapshot) {
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

  @override
  Widget build(BuildContext context) {
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
    final timeFormat = DateFormat('hh:mm a');
    final queueIds = batch.queueIds.where((id) => id != 'empty').toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
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
                  onDequeue: () => _confirmDequeue(context, queueIds[index]),
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

// Individual queue item card showing visitor information
class _QueueItemCard extends StatelessWidget {
  final String userId;
  final int index;
  final VoidCallback onDequeue;

  const _QueueItemCard({
    Key? key,
    required this.userId,
    required this.index,
    required this.onDequeue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Constants.purple,
          child: Text(
            index.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('Visitor ID: $userId'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: onDequeue,
        ),
      ),
    );
  }
}
