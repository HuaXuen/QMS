import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/providers/qrscanner_provider.dart';

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
                                  onDetect: _controller.onDetect,
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
