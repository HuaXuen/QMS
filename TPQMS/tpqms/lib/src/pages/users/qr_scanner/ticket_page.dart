import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/main_page_wrapper.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/common/resuable_widgets/reusable_buttons.dart';
import 'package:intl/intl.dart';
import 'package:tpqms/src/model/ticket_model.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart'; // Add this import
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class TicketPage extends StatefulWidget {
  const TicketPage({Key? key}) : super(key: key);

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  final Navigation navigation = Navigation();

  @override
  void initState() {
    super.initState();
    // Load ticket data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTicketData();
    });
  }

  // Helper method to convert TicketModel to display format
  Map<String, dynamic> _convertTicketToDisplayData(TicketModel ticket) {
    return {
      'purchaseTime': ticket.purchaseTime,
      'expirationTime': ticket.expirationTime,
      'price': ticket.price,
      'missedQueue': ticket.missedQueue,
      'ridesQueued': ticket.ridesQueued,
      'phoneNumber': ticket.phoneNumber,
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return MainPageWrapper(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: CustomAppBar(
          title: 'My Ticket',
          backgroundColor: Constants.purple,
        ),
        // Make the entire body scrollable
        body: SafeArea(
          child: SingleChildScrollView(
            // Add physics for better scroll behavior
            physics: const AlwaysScrollableScrollPhysics(),
            child: Consumer<TicketProvider>(
              builder: (context, ticketProvider, child) {
                // Show loading indicator while fetching data
                if (ticketProvider.isLoading) {
                  return SizedBox(
                    height: screenHeight * 0.7, // 70% of screen height
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Constants.purple,
                      ),
                    ),
                  );
                }

                // Show error message if there's an error
                if (ticketProvider.errorMessage != null) {
                  return SizedBox(
                    height: screenHeight * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ticketProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ticketProvider.refreshTicketData(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Main content section
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ticketProvider.hasTicket
                      ? TicketDetailsCard(
                          ticketData: _convertTicketToDisplayData(
                              ticketProvider.ticket!),
                        )
                      : SizedBox(
                          height: screenHeight * 0.7,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'You have not linked your ticket yet. Please scan the QR Code on your purchased ticket to bind ticket to account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CustomOutlinedButtonwithIcon(
                                  text: 'Scan Ticket',
                                  icon: Icons.qr_code_scanner,
                                  onPressed: () {
                                    navigation.navigateToQRScanner(
                                        context: context);
                                  },
                                  primaryColor: Constants.purple,
                                ),
                              ],
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// TicketDetailsCard remains largely the same, but with some adjustments
class TicketDetailsCard extends StatelessWidget {
  final Map<String, dynamic> ticketData;

  const TicketDetailsCard({
    Key? key,
    required this.ticketData,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Create QR data with all ticket information
        final qrData = {
          'purchaseTime': ticketData['purchaseTime'].toIso8601String(),
          'expirationTime': ticketData['expirationTime'].toIso8601String(),
          'phoneNumber': ticketData['phoneNumber'],
          'price': ticketData['price'],
          'missedQueue': ticketData['missedQueue'],
          'ridesQueued': ticketData['ridesQueued'],
          // Add timestamp to ensure QR updates when ticket data changes
          'timestamp': DateTime.now().toIso8601String(),
        };

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ticket QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Constants.purple.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: jsonEncode(qrData),
                      version: QrVersions.auto,
                      size: 250,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (context, error) => Center(
                        child: Text(
                          'Error generating QR code: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This QR code contains your ticket information for entry validation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Constants.purple,
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ticket Details',
              style: TextStyle(
                fontSize: 24,
                fontFamily: "Times New Roman",
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Ticket Purchased By: ',
              (ticketData['phoneNumber']),
              Icons.person,
            ),
            _buildDetailRow(
              'Purchase Time',
              _formatDateTime(ticketData['purchaseTime']),
              Icons.event_available,
            ),
            _buildDetailRow(
              'Expiration Time',
              _formatDateTime(ticketData['expirationTime']),
              Icons.event_busy,
            ),
            _buildDetailRow(
              'Price',
              'RM ${ticketData['price'].toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildDetailRow(
              'Missed Queues',
              '${ticketData['missedQueue']}',
              Icons.running_with_errors,
            ),
            _buildDetailRow(
              'Rides Queued',
              '${ticketData['ridesQueued']}',
              Icons.confirmation_number,
            ),
            _buildDetailRow(
              'Max No. of Rides Allowed to Virtual Queue',
              '2',
              Icons.confirmation_num_outlined,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showQRCode(context),
              icon: const Icon(Icons.qr_code),
              label: const Text('Show QR Code Before Entering the Park/Rides'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.purple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    // This method remains unchanged
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Constants.purple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
