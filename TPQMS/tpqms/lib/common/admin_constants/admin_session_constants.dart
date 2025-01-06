// Constants for session management
class AdminSessionConstants {
  static const sessionDuration = Duration(hours: 8); // Standard work shift
  static const inactivityTimeout = Duration(minutes: 30); // Common timeout
  static const sessionKey = 'admin_session';
}
