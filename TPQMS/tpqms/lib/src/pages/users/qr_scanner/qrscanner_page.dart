import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/providers/user_providers/qrscanner_provider.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final QrScannerController _controller = QrScannerController();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _controller.checkCameraPermission();
    if (!hasPermission) {
      await _controller.requestCameraPermission();
    }
  }

  Future<void> _handleScanResult(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      try {
        // Parse the QR code data
        final ticketData = jsonDecode(barcode.rawValue ?? '');

        // Get the TicketProvider using the widget's context
        final ticketProvider =
            Provider.of<TicketProvider>(context, listen: false);

        // Attempt to bind the ticket
        final result = await ticketProvider.bindTicketToCurrentUser(ticketData);

        // Check if widget is still mounted before showing UI feedback
        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
          Navigator.pushReplacementNamed(context, Constants.HomePage);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(result['message'])));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid ticket QR code')));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.purple),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on, color: Color(0xFF8A4FFF)),
            onPressed: _controller.toggleTorch,
          ),
          IconButton(
            icon: Icon(Icons.switch_camera, color: Color(0xFF8A4FFF)),
            onPressed: _controller.switchCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scan the QR code to validate your ticket',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Constants.purple,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _controller.hasCameraPermission,
                              builder: (context, hasPermission, child) {
                                if (!hasPermission) {
                                  return Center(
                                    child: Text(
                                      'Camera permission is required',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }
                                return MobileScanner(
                                  controller: _controller.cameraController,
                                  onDetect: _handleScanResult,
                                );
                              },
                            ),
                          ),
                        ),
                        QRScannerOverlay(
                          borderColor: Constants.purple,
                          scanAreaHeight: 500,
                          scanAreaWidth: 500,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Scanning will be started automatically',
                    style: TextStyle(color: Color(0xFF8A4FFF), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder(
              valueListenable: _controller.scannedCode,
              builder: (context, value, child) {
                return Text(
                  'Scanned Code: $value',
                  style: TextStyle(color: Color(0xFF8A4FFF)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
