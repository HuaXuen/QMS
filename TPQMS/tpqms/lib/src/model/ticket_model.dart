import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String ticketId;
  final String userId;
  final DateTime purchaseTime;
  final DateTime expirationTime;
  final bool isValid;
  final double price;

  TicketModel({
    required this.ticketId,
    required this.userId,
    required this.purchaseTime,
    required this.expirationTime,
    required this.isValid,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'purchaseTime': Timestamp.fromDate(purchaseTime),
      'expirationTime': Timestamp.fromDate(expirationTime),
      'isValid': isValid,
    };
  }

  factory TicketModel.fromMap(String id, Map<String, dynamic> map) {
    return TicketModel(
      ticketId: map['ticketId'] ?? '',
      userId: map['userId'] ?? '',
      purchaseTime: (map['purchaseTime'] as Timestamp).toDate(),
      expirationTime: (map['expirationTime'] as Timestamp).toDate(),
      isValid: map['isValid'] ?? false,
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
