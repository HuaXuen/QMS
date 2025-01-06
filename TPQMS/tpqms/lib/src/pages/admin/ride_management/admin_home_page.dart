// admin_home_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/pages/admin/ride_management/queue_management_dialog.dart';
import 'package:tpqms/src/pages/admin/shared/admin_page_wrapper.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/src/providers/admin_providers/admin_ride_provider.dart';
import 'package:tpqms/src/providers/admin_providers/admin_auth_provider.dart'; // New import
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popup.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _setupSessionListener();
    _initializeAdminId();
  }

  void _setupSessionListener() {
    final adminAuthProvider = context.read<AdminAuthProvider>();
    adminAuthProvider.addListener(() {
      if (adminAuthProvider.currentAdmin == null) {
        Navigator.of(context).pushReplacementNamed(Constants.AdminLoginPage);
      }
    });
  }

  void _initializeAdminId() {
    final adminAuthProvider = context.read<AdminAuthProvider>();
    _adminId = adminAuthProvider.currentAdmin?.adminId;
    if (_adminId == null) {
      Navigator.of(context).pushReplacementNamed(Constants.AdminLoginPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AdminAuthProvider>().registerActivity();
      },
      child: AdminPageWrapper(
        currentIndex: 0,
        child: Scaffold(
          backgroundColor: Constants.secondaryBackground,
          appBar: AppBar(
            title: const Text(
              'Ride Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: _adminId == null
              ? const Center(child: Text('No valid admin session'))
              : StreamBuilder<List<RideModel>>(
                  stream: context.read<RideProvider>().ridesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final rides = snapshot.data ?? [];

                    if (rides.isEmpty) {
                      return const Center(child: Text('No rides available'));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 88,
                      ),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return SingleChildScrollView(
                            padding: EdgeInsets.only(
                              top: 16,
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 16,
                            ),
                            child: AdminRideCard(
                              ride: ride,
                              adminId: _adminId!,
                            ));
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
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
                await context.read<AdminAuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .pushReplacementNamed(Constants.LoginPage);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully logged out.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to logout: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: const Color(0xFF8B5CF6)),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminRideCard extends StatelessWidget {
  final RideModel ride;
  final String adminId;

  const AdminRideCard({
    Key? key,
    required this.ride,
    required this.adminId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminRideProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Constants.purple.withOpacity(0.1),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.purple.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRideHeader(context),
          _buildStatusControls(context, adminProvider),
          // Replace the currentBatchId check with StreamBuilder for available batches
          StreamBuilder<List<BatchModel>>(
            stream: adminProvider.streamCurrentHourBatches(ride.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading batches: ${snapshot.error}'),
                );
              }

              final batches = snapshot.data ?? [];
              if (batches.isEmpty) {
                return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No active batches available',
                      style: TextStyle(color: Colors.white),
                    ));
              }

              // Get the current active batch (first in the sorted list)
              final currentBatch = batches.first;

              return Column(
                children: [
                  _buildBatchSection(context, currentBatch),
                  _buildActionButtons(context, adminProvider, currentBatch),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRideHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.purple.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  ride.category,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(ride.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              ride.status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusControls(
      BuildContext context, AdminRideProvider adminProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatusButton(
            context: context,
            provider: adminProvider,
            status: 'Available',
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            context: context,
            provider: adminProvider,
            status: 'Under Maintenance',
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _buildStatusButton(
            context: context,
            provider: adminProvider,
            status: 'Closed',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required BuildContext context,
    required AdminRideProvider provider,
    required String status,
    required Color color,
  }) {
    final isCurrentStatus = ride.status.toLowerCase() == status.toLowerCase();

    return Expanded(
      flex: 1, // Ensure equal flex for all buttons
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 110, // Set minimum width for consistency
          minHeight: 45, // Set minimum height for consistency
        ),
        child: ElevatedButton(
          onPressed: isCurrentStatus
              ? null
              : () => _updateStatus(context, provider, status),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCurrentStatus ? color : Colors.grey[500],
            disabledBackgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            minimumSize: const Size.fromHeight(45), // Consistent height
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isCurrentStatus ? Colors.white : Colors.grey[200],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modified to show batch information
  Widget _buildBatchSection(BuildContext context, BatchModel? batch) {
    if (batch == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No active batches in the current hour',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }
    final startTime =
        DateTime.fromMillisecondsSinceEpoch(batch.startAt, isUtc: true);
    final endTime =
        DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
    final timeFormat = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Batch',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.group, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${batch.queueIds.where((id) => id != "empty").length} visitors in queue',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modified to use current batch
  Widget _buildActionButtons(
    BuildContext context,
    AdminRideProvider adminProvider,
    BatchModel? currentBatch,
  ) {
    if (currentBatch == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showQueueManagement(context, currentBatch),
              icon: const Icon(Icons.people),
              label: const Text('Manage Queue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.purple.withOpacity(0.7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _completeBatch(context, adminProvider, currentBatch),
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Batch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action Handlers
  void _updateStatus(
      BuildContext context, AdminRideProvider provider, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Change'),
        content:
            Text('Are you sure you want to change the status to $newStatus?'),
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
              try {
                print('[STATUS-CHANGE] Attempting to change status:');
                print('[STATUS-CHANGE] Ride ID: ${ride.id}');
                print('[STATUS-CHANGE] From: ${ride.status} -> To: $newStatus');
                print('[STATUS-CHANGE] Admin ID: $adminId');

                await provider.updateRideStatus(
                  rideId: ride.id,
                  newStatus: newStatus,
                  adminId: adminId,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status updated to $newStatus'),
                      backgroundColor: Constants.purple,
                    ),
                  );
                }

                print('[STATUS-CHANGE] Status change successful');
              } catch (e) {
                print('[STATUS-CHANGE] Error: $e');
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Constants.purple),
            ),
          ),
        ],
      ),
    );
  }

  // Modified to use provided batch
  void _showQueueManagement(BuildContext context, BatchModel batch) {
    showDialog(
      context: context,
      builder: (context) => QueueManagementDialog(
        ride: ride,
        adminId: adminId,
      ),
    );
  }

  // Modified to use provided batch
  // Replace the existing _completeBatch method in AdminRideCard with this:
  void _completeBatch(
      BuildContext context, AdminRideProvider provider, BatchModel batch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Batch'),
        content:
            const Text('Are you sure you want to complete the current batch?'),
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
              // Dismiss the dialog first
              Navigator.of(context).pop();

              try {
                await provider.completeBatch(
                  rideId: ride.id,
                  batchId: batch.id,
                  adminId: adminId,
                );

                if (context.mounted) {
                  // Show success dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Success'),
                      content: const Text('Batch completed successfully'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  // Show error dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text(e.toString()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'under maintenance':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
