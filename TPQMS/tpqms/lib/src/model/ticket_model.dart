import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String ticketId; //included in the ticket
  final String phoneNumber;
  final String userId; //currentUser userid
  final DateTime purchaseTime;
  final DateTime expirationTime;
  final bool isValid;
  final double price;
  final int missedQueue;
  final int ridesQueued;

  TicketModel({
    required this.ticketId,
    //required this.ticketType,
    required this.phoneNumber,
    required this.userId,
    required this.purchaseTime,
    required this.expirationTime,
    required this.isValid,
    required this.price,
    required this.missedQueue,
    required this.ridesQueued,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      //'ticketType': ticketType,
      'phoneNumber': phoneNumber,
      'userId': userId,
      'purchaseTime': Timestamp.fromDate(purchaseTime),
      'expirationTime': Timestamp.fromDate(expirationTime),
      'isValid': isValid,
      'price': price,
      'missedQueue': missedQueue,
      'ridesQueued': ridesQueued,
    };
  }

  factory TicketModel.fromMap(String id, Map<String, dynamic> map) {
    return TicketModel(
      ticketId: map['ticketId'] ?? '',
      //ticketType: map['ticketType'] ?? '',
      userId: map['userId'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      purchaseTime: (map['purchaseTime'] as Timestamp).toDate(),
      expirationTime: (map['expirationTime'] as Timestamp).toDate(),
      isValid: map['isValid'] ?? false,
      price: (map['price'] ?? 0).toDouble(),
      missedQueue: map['missedQueue'] ?? 0,
      ridesQueued: map['ridesQueued'] ?? 0,
    );
  }
}
