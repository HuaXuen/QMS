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
    return MainPageWrapper(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: CustomAppBar(
          title: 'My Ticket',
          backgroundColor: Constants.purple,
        ),
        body: Consumer<TicketProvider>(
          builder: (context, ticketProvider, child) {
            // Show loading indicator while fetching data
            if (ticketProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Constants.purple,
                ),
              );
            }

            // Show error message if there's an error
            if (ticketProvider.errorMessage != null) {
              return Center(
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
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ticketProvider.hasTicket
                  ? TicketDetailsCard(
                      ticketData:
                          _convertTicketToDisplayData(ticketProvider.ticket!),
                    )
                  : Center(
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
                              navigation.navigateToQRScanner(context: context);
                            },
                            primaryColor: Constants.purple,
                          ),
                        ],
                      ),
                    ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
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
