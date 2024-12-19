import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';
import 'package:tpqms/utilities/assets_manager.dart';

class RideDetailsBottomSheet extends StatefulWidget {
  final RideModel rideData;
  final String folderPath;
  final String imagePath;
  final VoidCallback onQueuePressed;

  const RideDetailsBottomSheet({
    Key? key,
    required this.rideData,
    required this.folderPath,
    required this.imagePath,
    required this.onQueuePressed,
  }) : super(key: key);

  @override
  State<RideDetailsBottomSheet> createState() => _RideDetailsBottomSheetState();
}

class _RideDetailsBottomSheetState extends State<RideDetailsBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Schedule the image loading for the next frame when context is available
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
    return ClipPath(
      clipper: SerratedClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Constants.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image section
            Consumer<ImageProviderService>(
              builder: (context, imageProvider, child) {
                if (imageProvider.isLoading) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: imageProvider.imageUrl != null
                          ? NetworkImage(imageProvider.imageUrl!)
                          : const AssetImage(AssetsManager.imageError),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),

            // Ride details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.rideData.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.rideData.category,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                          widget.rideData.status), // Solid green for available
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Status: ${widget.rideData.status}',
                      style: const TextStyle(
                        color: Colors.white, // White text
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.height, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Min. Height: ${widget.rideData.heightRequirement}cm',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Queue Time: ${widget.rideData.queueTime} mins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Queue Now button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: ElevatedButton(
                onPressed: (widget.rideData.status.toLowerCase() !=
                            'under maintenance' &&
                        widget.rideData.status.toLowerCase() != 'closed')
                    ? widget.onQueuePressed
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (widget.rideData.status.toLowerCase() !=
                              'under maintenance' &&
                          widget.rideData.status.toLowerCase() != 'closed')
                      ? Colors.blue // Active button color
                      : Colors.grey.shade600, // Disabled button color
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Queue Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.white,
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

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return Colors.green; // Solid green color
    case 'closed':
      return Colors.red;
    case 'under maintenance':
      return Colors.yellow.shade700;
    default:
      return Colors.grey; // Fallback for unrecognized statuses
  }
}

class SerratedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double serrationWidth = 20.0;
    double serrationHeight = 5.0;
    double gapWidth = 7.0; // Width of the gap between each arc

    path.lineTo(0, serrationHeight);

    for (double x = 0; x < size.width; x += serrationWidth + gapWidth) {
      path.arcToPoint(
        Offset(x + serrationWidth, serrationHeight),
        radius: Radius.circular(serrationHeight),
        clockwise: false,
      );
      path.lineTo(x + serrationWidth + gapWidth, serrationHeight);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
