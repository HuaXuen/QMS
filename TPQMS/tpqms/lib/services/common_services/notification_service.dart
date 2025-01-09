import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:tpqms/src/model/batch_model.dart';
import 'package:tpqms/src/model/ride_model.dart';

class NotificationService {
  // Single instance of notifications plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  // Channel IDs for Android
  static const String _notificationChannelId = 'ride_notifications';
  static const String _notificationChannelName = 'Ride Notifications';
  static const String _notificationChannelDescription =
      'Notifications for theme park ride updates';

  NotificationService()
      : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    // Initialize timezone data when service is created
    tz.initializeTimeZones();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Request permission from the user (important for Android 13+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print('Notification permission denied.');
        return; // Exit if permission is not granted
      }
    }
    // Define notification settings for Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combine platform-specific settings
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    // Initialize the plugin with our settings
    try {
      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        // This callback handles notification taps
        onDidReceiveNotificationResponse: (details) {
          print('Notification tapped: ${details.payload}');
          // You can add navigation logic here later
        },
      );
      print('Notifications initialized: $initialized');
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }
  }

  Future<bool> scheduleRideNotification(
    RideModel ride,
    BatchModel batch,
    Duration beforeTime,
  ) async {
    try {
      final malaysiaTimeZone = tz.getLocation('Asia/Kuala_Lumpur');

      // Ensure the time is parsed as UTC
      final utcDateTime =
          DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);

      // Convert UTC DateTime to Malaysia timezone
      final batchEndTime = tz.TZDateTime.from(utcDateTime, malaysiaTimeZone);

      // Calculate notification time (subtracting the beforeTime duration)
      var notificationTime = batchEndTime.subtract(beforeTime);

      // Adjust notification time by brute-forcing: subtract 8 hours
      notificationTime = notificationTime.subtract(const Duration(hours: 8));

      // Get current time in Malaysia timezone
      final now = tz.TZDateTime.now(malaysiaTimeZone);
      // Debug logging
      print('[NOTIFICATION] Current time (MY): $now');
      print('[NOTIFICATION] endAt: ${batch.endAt}');
      print('[NOTIFICATION] endAt: ${utcDateTime}');

      print('[NOTIFICATION] Batch end time (MY): $batchEndTime');
      print('[NOTIFICATION] Planned notification time (MY): $notificationTime');
      // Use deterministic notification ID
      final notificationId = batch.deterministicNotificationId;
      print(
          '[NOTIFICATION] Scheduling notification with ID: $notificationId for batch: ${batch.id}');

      if (!notificationTime.isAfter(now)) {
        print('[NOTIFICATION] Cannot schedule - time has already passed');
        return false;
      }

      // Schedule the notification
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Almost Your Turn!',
        'Your turn for ${ride.name} is coming up in ${beforeTime.inMinutes} minutes!',
        notificationTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
            tag: 'ride_${ride.id}_batch_${batch.id}',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '${ride.id}|${batch.id}',
      );

      print(
          '[NOTIFICATION TESTING] Successfully scheduled notification for ${ride.name} at $notificationTime');
      return true;
    } catch (e) {
      print('[NOTIFICATION TESTING] Failed to schedule notification: $e');
      return false;
    }
  }

  Future<bool> cancelRideNotification(BatchModel batch) async {
    try {
      // Cancel using the same ID we used to schedule
      final notificationId = batch.deterministicNotificationId;
      print(
          '[NOTIFICATION] Attempting to cancel notification with ID: $notificationId for batch: ${batch.id}');

      await _notificationsPlugin.cancel(notificationId);
      print('Successfully cancelled notification for batch ${batch.id}');
      return true;
    } catch (e) {
      print('Failed to cancel notification: $e');
      return false;
    }
  }

  Future<bool> sendImmediateEnqueueNotification(
      RideModel ride, BatchModel batch) async {
    try {
      final notificationId = batch.deterministicNotificationId;
      // Convert timestamp to DateTime
      final endTime =
          DateTime.fromMillisecondsSinceEpoch(batch.endAt, isUtc: true);
      // Format the time in 12-hour format with AM/PM
      final formattedTime = DateFormat('h:mm a').format(endTime);
      await _notificationsPlugin.show(
        notificationId,
        'Joined New Queue!',
        'Your turn for ${ride.name} is at ${formattedTime}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send immediate notification: $e');
      return false;
    }
  }

  Future<bool> sendMissedQueueNotification(
      RideModel ride, BatchModel batch) async {
    try {
      final notificationId = batch.deterministicNotificationId;
      await _notificationsPlugin.show(
        notificationId,
        'Missed Queue Notice',
        'You have been marked as missed for ${ride.name}. This will affect your queue history.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send missed queue notification: $e');
      return false;
    }
  }

  Future<bool> sendImmediateDequeueNotification(
      RideModel ride, BatchModel batch) async {
    try {
      final notificationId = batch.deterministicNotificationId;
      await _notificationsPlugin.show(
        notificationId,
        'Removed from Queue!',
        'You have dequeued from ${ride.name}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send immediate notification: $e');
      return false;
    }
  }

  Future<bool> sendDequeueNotification(RideModel ride, BatchModel batch) async {
    try {
      final notificationId = batch.deterministicNotificationId;
      await _notificationsPlugin.show(
        notificationId,
        'You have been deqeued by an admin',
        'Your turn for ${ride.name} has been cancelled, you may consult a personnel if you think there was an error.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send immediate notification: $e');
      return false;
    }
  }

  Future<bool> sendDistanceWarningNotification(
      RideModel ride, String distance) async {
    try {
      final notificationId = ride.hashCode; // Unique ID based on ride

      await _notificationsPlugin.show(
        notificationId,
        'Proximity Warning',
        'You are currently ${distance} from ${ride.name}. Please return on time for your ride',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send distance warning notification: $e');
      return false;
    }
  }

  Future<bool> sendMaintenanceNotification(
    RideModel ride, {
    List<String>? affectedVisitors,
  }) async {
    try {
      final notificationId = ride.hashCode;
      await _notificationsPlugin.show(
        notificationId,
        'Ride Under Maintenance',
        '${ride.name} is now under maintenance. Your queue position has been cancelled.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send maintenance notification: $e');
      return false;
    }
  }

  Future<bool> sendClosedNotification(
    RideModel ride, {
    List<String>? affectedVisitors,
  }) async {
    try {
      final notificationId = ride.hashCode;
      await _notificationsPlugin.show(
        notificationId,
        'Ride Closed',
        '${ride.name} is now closed. Your queue position has been cancelled.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _notificationChannelId,
            _notificationChannelName,
            channelDescription: _notificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableLights: true,
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Failed to send maintenance notification: $e');
      return false;
    }
  }
}
