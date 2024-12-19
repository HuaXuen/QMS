import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';
import 'package:tpqms/utilities/assets_manager.dart';

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
    return Scaffold(
      backgroundColor: Constants.black,
      body: Stack(
        children: [
          // Full-width image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer<ImageProviderService>(
              builder: (context, imageProvider, child) {
                if (imageProvider.isLoading) {
                  return const SizedBox(
                    height: 350,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return imageProvider.imageUrl != null
                    ? Image.network(
                        imageProvider.imageUrl!,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        AssetsManager.imageError,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                      );
              },
            ),
          ),
          // Content container filling remaining height
          Positioned(
            top: 300, // Slight overlap
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height - 300,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', widget.ride.status),
                    _buildDetailRow(
                        'Wait Time', '${widget.ride.queueTime} minutes'),
                    _buildDetailRow('Category', widget.ride.category),
                    _buildDetailRow('Height Requirement',
                        '${widget.ride.heightRequirement}cm'),
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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label (ensures it stays on one line)
          Expanded(
            flex: 4, // Label column width
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          // Colon and space
          const Text(
            ":",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8), // Space after the colon
          // Value
          Expanded(
            flex: 5, // Value column width
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
