import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/services/common_services/ticket_service.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/ticket_model.dart';

class TicketProvider extends ChangeNotifier {
  final TicketService _ticketService;
  final FirestoreService _firestoreService;
  final UserService _userService;

  TicketProvider(
      this._ticketService, this._firestoreService, this._userService);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> bindTicketToCurrentUser(String userId, List<String> childrenIds,
      TicketModel scannedTicket) async {
    _isLoading = true;
    notifyListeners();

    try {
      var generatedChildIds = _ticketService.generateChildrenIds(
          scannedTicket.numOfChildren, userId);

      // Generate the child IDs based on numOfChildren

      // Creating the ticket model with the provided data
      TicketModel ticket = TicketModel(
        ticketId: scannedTicket.ticketId, //get from ticket qr code
        userId: userId,
        //ticketType: scannedTicket.ticketType,
        numOfChildren: scannedTicket.numOfChildren,
        expirationTime:
            DateTime.now().add(Duration(days: 1)), // Example expiration time
        isValid: false,
        price: scannedTicket.price,
        missedQueue: 0,
        purchaseTime: DateTime.now(),
        ridesQueued: 0,
      );

      // Convert the TicketModel to a Map to store in Firestore
      Map<String, dynamic> ticketData = await ticket.toMap();

      // Add ticket to Firestore
      await _ticketService.addTicket(ticket);

      // Add each child document under the ticket
      for (int i = 0; i < scannedTicket.numOfChildren; i++) {
        String childId = 'child${i + 1}';
        await _ticketService.updateChildId(
          scannedTicket.ticketId, // Parent ticket ID
          childId, // Child document ID
          {
            'childId': childId,
            'parentUserId': scannedTicket.userId,
          },
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating ticket: $e');
    }
  }
}

//parent will specify childrens in their ticket, no height required, then the ride operator will check the childs height when they get to the ride