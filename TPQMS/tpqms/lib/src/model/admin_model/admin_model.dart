// admin_model.dart
class AdminModel {
  final String adminId;
  final String employeeCode;
  final String username;
  final bool status;

  AdminModel({
    required this.adminId,
    required this.employeeCode,
    required this.username,
    required this.status,
  });

  factory AdminModel.fromMap(String id, Map<String, dynamic> map) {
    return AdminModel(
      adminId: id,
      employeeCode: map['employee_code'] ?? '',
      username: map['username'] ?? '',
      status: map['status'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employee_code': employeeCode,
      'username': username,
      'status': status,
    };
  }
}

// admin_model.dart

class AdminAction {
  final String id;
  final String adminId;
  final String rideId;
  final String action;
  final int timestamp;
  final Map<String, dynamic> details;

  AdminAction({
    required this.id,
    required this.adminId,
    required this.rideId,
    required this.action,
    required this.timestamp,
    required this.details,
  });

  factory AdminAction.fromMap(String id, Map<String, dynamic> map) {
    return AdminAction(
      id: id,
      adminId: map['adminId'] ?? '',
      rideId: map['rideId'] ?? '',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'rideId': rideId,
      'action': action,
      'timestamp': timestamp,
      'details': details,
    };
  }
}
