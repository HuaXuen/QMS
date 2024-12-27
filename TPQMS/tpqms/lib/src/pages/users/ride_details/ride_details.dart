import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_buttons.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
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
  String? _selectedTimeslot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<ImageProviderService>()
            .loadImage(widget.folderPath, widget.imagePath);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = context.read<RideProvider>();

    return Scaffold(
      backgroundColor: Constants.black,
      body: Stack(
        children: [
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
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height - 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
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
                    StreamBuilder<List<BatchModel>>(
                      stream: rideProvider
                          .streamAvailableBatchesForRide(widget.ride.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final batches = snapshot.data ?? [];

                        if (batches.isEmpty) {
                          return const Text(
                            'No available timeslots for this hour.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        List<String> timeslots = batches.map((batch) {
                          final startTime =
                              DateTime.fromMillisecondsSinceEpoch(batch.startAt)
                                  .toUtc();
                          final endTime =
                              DateTime.fromMillisecondsSinceEpoch(batch.endAt)
                                  .toUtc();

                          final formattedStartTime =
                              DateFormat('h:mm a').format(startTime);
                          final formattedEndTime =
                              DateFormat('h:mm a').format(endTime);

                          return '$formattedStartTime - $formattedEndTime';
                        }).toList();
                        print("Please select a timeslot: $timeslots");

                        return CustomPopupMenu(
                          value: _selectedTimeslot ?? timeslots.first,
                          items: timeslots,
                          onSelected: (value) {
                            setState(() {
                              _selectedTimeslot = value;
                            });
                          },
                          isOpen: false,
                          onOpened: () {},
                          onCanceled: () {},
                          labelTextColor: Constants.black,
                          itemTextColor: Constants.black,
                          containerBackgroundColor: Constants.white,
                          containerBorderColorDefault: Constants.darkGrey,
                          containerBorderColorOpen: Constants.grey,
                          dropdownArrowColor: Constants.black,
                          menuBackgroundColor: Constants.white,
                          selectedValueTextColor: Constants.black,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', widget.ride.status),
                    _buildDetailRow(
                        'Wait Time', '${widget.ride.queueTime} minutes'),
                    _buildDetailRow('Category', widget.ride.category),
                    _buildDetailRow('Height Requirement',
                        '${widget.ride.heightRequirement}cm'),
                    _buildDetailRow('Max Riders Allowed',
                        '${widget.ride.numOfRidersAllowed}'),
                    const SizedBox(height: 20),
                    if (_selectedTimeslot != null)
                      CustomElevatedButton(
                        text: "Queue Now",
                        onPressed: () {
                          // Handle queue logic here
                          print("Queued for $_selectedTimeslot");
                        },
                        backgroundColor: Constants.purple,
                        foregroundColor: Constants.white,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                color: Colors.grey, // Updated for better readability
              ),
            ),
          ),
        ],
      ),
    );
  }
}
