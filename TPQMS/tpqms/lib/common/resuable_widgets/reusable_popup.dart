import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';

enum PopupType {
  success,
  error,
  warning,
}

class ReusablePopup {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    required PopupType type,
    VoidCallback? onConfirm,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    switch (type) {
      case PopupType.success:
        _showSuccessDialog(
          context: context,
          title: title,
          message: message,
          onConfirm: onConfirm,
        );
        break;
      case PopupType.error:
      case PopupType.warning:
        _showSnackBar(
          context: context,
          title: title,
          message: message,
          type: type,
          duration: autoCloseDuration,
        );
        break;
    }
  }

  static void _showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onConfirm != null) {
                      onConfirm();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Constants.secondaryBackground,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String title,
    required String message,
    required PopupType type,
    required Duration duration,
  }) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData icon;

    switch (type) {
      case PopupType.error:
        backgroundColor = Colors.red;
        icon = Icons.error_outline;
        break;
      case PopupType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning_amber;
        break;
      default:
        backgroundColor = Colors.green;
        icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
