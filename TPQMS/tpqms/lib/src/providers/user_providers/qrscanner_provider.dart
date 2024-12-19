import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerController {
  final MobileScannerController cameraController = MobileScannerController();
  final ValueNotifier<String> scannedCode = ValueNotifier('');
  final ValueNotifier<bool> hasCameraPermission = ValueNotifier(false);

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    hasCameraPermission.value = status.isGranted;
  }

  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    hasCameraPermission.value = status.isGranted;
    return status.isGranted;
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      scannedCode.value = barcode.rawValue ?? 'Failed to scan';
    }
  }

  void toggleTorch() {
    cameraController.toggleTorch();
  }

  void switchCamera() {
    cameraController.switchCamera();
  }

  void dispose() {
    cameraController.dispose();
  }
}
