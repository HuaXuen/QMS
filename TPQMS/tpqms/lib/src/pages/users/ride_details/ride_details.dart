import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_buttons.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popup.dart';
import 'package:tpqms/services/common_services/ticket_service.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/queue_model.dart';
import 'package:tpqms/src/model/selected_batch_info.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';
import 'package:tpqms/utilities/assets_manager.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popupmenu.dart';
import 'package:intl/intl.dart';

class RideDetailsPage extends StatefulWidget {
  final RideModel ride;
  final String folderPath;
  final String imagePath;

  const RideDetailsPage({
    Key? key,
    required this.ride,
    required this.folderPath,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  SelectedBatchInfo? _selectedBatchInfo;
  bool _isQueuing = false;
  List<BatchModel>? _availableBatches; // Cached batch data

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context
            .read<ImageProviderService>()
            .loadImage(widget.folderPath, widget.imagePath);
        context.read<UserInfoProvider>().getHeight();
        context.read<TicketProvider>().loadTicketData();
        await _loadAvailableBatches();
      }
    });
  }

  Future<void> _loadAvailableBatches() async {
    try {
      final batches = await context
          .read<RideProvider>()
          .streamAvailableBatchesForRide(widget.ride.id)
          .first;

      if (mounted) {
        setState(() {
          _availableBatches = batches;

          // Validate existing selection
          if (_selectedBatchInfo != null) {
            final batchStillAvailable =
                batches.any((b) => b.id == _selectedBatchInfo!.batch.id);
            if (!batchStillAvailable) {
              _selectedBatchInfo = null; // Clear invalid selection
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading batches: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper method to handle queuing process
  // In RideDetailsPage
  // Helper method to handle queuing process
  Future<void> _handleQueue(BuildContext context) async {
    if (_selectedBatchInfo == null) return;

    await runWithLoadingState(() async {
      print('\n========== QUEUE REQUEST STARTED ==========');
      final queueProvider = context.read<QueueProvider>();
      final ticketProvider = context.read<TicketProvider>();

      print('\n🎫 Validating Ticket State...');
      if (!ticketProvider.hasTicket) {
        print('❌ No valid ticket found in state');
        throw Exception('No valid ticket found');
      }

      print('\n🔍 Checking Queue Limits...');
      if (ticketProvider.ticket!.ridesQueued >= 2) {
        print('❌ Queue limit exceeded');
        throw Exception('Maximum number of rides queued (2) reached');
      }

      print('\n📋 Validating Selected Batch...');
      final batch = _availableBatches?.firstWhere(
        (b) => b.id == _selectedBatchInfo!.batch.id,
        orElse: () => throw Exception('Batch not found or unavailable'),
      );

      if (batch == null ||
          batch.batchStatus == 'completed' ||
          batch.queueFilledAt != 'Not Filled Up') {
        print('❌ Invalid batch state');
        throw Exception('This timeslot is no longer available');
      }

      print('\n🚀 Calling QueueProvider.queueForRide...');
      final result = await queueProvider
          .queueForRide(
        rideId: widget.ride.id,
        batchId: _selectedBatchInfo!.batch.id,
        startAt: _selectedBatchInfo!.batch.startAt,
        endAt: _selectedBatchInfo!.batch.endAt,
      )
          .timeout(Duration(seconds: 8), onTimeout: () {
        print('⏰ Queue operation timed out');
        throw Exception('Queuing request timed out');
      });

      print('\n📥 Queue Result Received:');
      print('Success: ${result['success']}');
      print('Message: ${result['message']}');

      if (result['success']) {
        print('\n✨ Queue Successful! Showing success dialog...');
        if (!mounted) return;

        ReusablePopup.show(
          context: context,
          title: 'Success',
          message: 'Successfully queued for ${widget.ride.name}',
          type: PopupType.success,
          onConfirm: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, Constants.QueuePage);
          },
        );
      } else {
        print('\n❌ Queue operation failed with message: ${result['message']}');
        throw Exception(result['message']);
      }

      print('\n========== QUEUE REQUEST COMPLETED ==========\n');
    });
  }

  Future<void> runWithLoadingState(Future<void> Function() operation) async {
    setState(() => _isQueuing = true);
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isQueuing = false);
      }
    }
  }

  // Build the batch selection dropdown
  Widget _buildBatchSelection(List<BatchModel> batches) {
    return StreamBuilder<QueueModel?>(
      stream: context.read<QueueProvider>().getRideQueueStatus(widget.ride.id),
      builder: (context, queueSnapshot) {
        final isAlreadyQueued = queueSnapshot.hasData;

        List<String> timeslots = batches.map((batch) {
          final startTime =
              DateTime.fromMillisecondsSinceEpoch(batch.startAt).toUtc();
          final endTime =
              DateTime.fromMillisecondsSinceEpoch(batch.endAt).toUtc();
          return '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
        }).toList();

        List<SelectedBatchInfo> batchInfos = List.generate(
          batches.length,
          (index) => SelectedBatchInfo(
            displayString: timeslots[index],
            batch: batches[index],
          ),
        );

        return CustomPopupMenu(
          value: _selectedBatchInfo?.displayString ?? timeslots.first,
          items: timeslots,
          onSelected: (value) {
            final selectedIndex = timeslots.indexOf(value);
            setState(() => _selectedBatchInfo = batchInfos[selectedIndex]);
          },
          isOpen: false,
          onOpened: () {},
          onCanceled: () {},
          labelTextColor: Constants.black,
          itemTextColor: isAlreadyQueued ? Colors.grey : Constants.black,
          containerBackgroundColor: Constants.white,
          containerBorderColorDefault: Constants.darkGrey,
          containerBorderColorOpen: Constants.grey,
          dropdownArrowColor: Constants.black,
          menuBackgroundColor: Constants.white,
          selectedValueTextColor: Constants.black,
        );
      },
    );
  }

  Widget _buildQueueButton(bool meetsHeightRequirement) {
    return StreamBuilder<QueueModel?>(
      stream: context.read<QueueProvider>().getRideQueueStatus(widget.ride.id),
      builder: (context, queueSnapshot) {
        final bool isAlreadyQueued = queueSnapshot.hasData;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          child: CustomElevatedButton(
            text: isAlreadyQueued ? "Already Queued" : "Queue Now",
            onPressed:
                (isAlreadyQueued || !meetsHeightRequirement || _isQueuing)
                    ? null
                    : () => _handleQueue(context),
            backgroundColor: isAlreadyQueued ? Colors.grey : Constants.purple,
            foregroundColor: Constants.white,
            child: _isQueuing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    isAlreadyQueued ? "Already Queued" : "Queue Now",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Constants.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.read<RideProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Constants.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer<ImageProviderService>(
                builder: (context, imageProvider, child) {
                  if (imageProvider.isLoading) {
                    return const SizedBox(
                      height: 280,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return imageProvider.imageUrl != null
                      ? Image.network(
                          imageProvider.imageUrl!,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          AssetsManager.imageError,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        );
                },
              ),
            ),
            // Content section
            Positioned(
              top: 220,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ride.name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontFamily: "Times New Roman",
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Available Timeslots:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Hourly batches are displayed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<UserInfoProvider>(
                          builder: (context, userProvider, child) {
                            final userHeight =
                                int.parse(userProvider.height ?? '0');

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                StreamBuilder<List<BatchModel>>(
                                  stream: rideProvider
                                      .streamAvailableBatchesForRide(
                                          widget.ride.id),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasError) {
                                      return Text(
                                        'Error: ${snapshot.error}',
                                        style:
                                            const TextStyle(color: Colors.red),
                                      );
                                    }

                                    final batches = snapshot.data ?? [];
                                    if (batches.isEmpty) {
                                      return const Text(
                                        'No available timeslots for this hour.',
                                        style: TextStyle(color: Colors.grey),
                                      );
                                    }

                                    return _buildBatchSelection(batches);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow('Status', widget.ride.status),
                                _buildDetailRow('Wait Time',
                                    '${widget.ride.queueTime} minutes'),
                                _buildDetailRow(
                                    'Category', widget.ride.category),
                                _buildDetailRow('Height Requirement',
                                    '${widget.ride.heightRequirement}cm'),
                                _buildDetailRow('Max Riders Allowed',
                                    '${widget.ride.numOfRidersAllowed}'),
                                const SizedBox(height: 20),
                                if (userHeight < widget.ride.heightRequirement)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'Your height (${userHeight}cm) does not meet the minimum requirement of ${widget.ride.heightRequirement}cm',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (_selectedBatchInfo != null)
                                  _buildQueueButton(userHeight >=
                                      widget.ride.heightRequirement),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                fontFamily: "Times New Roman",
                color: Colors.black,
              ),
            ),
          ),
          const Text(
            ":",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
