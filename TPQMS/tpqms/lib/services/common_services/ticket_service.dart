import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tpqms/src/model/ticket_model.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';

class TicketService {
  final FirestoreService _firestoreService;
  final String _collection = 'tickets';

  TicketService(this._firestoreService);

  Future<void> addTicket(TicketModel ticket) async {
    await _firestoreService.addDocument(
        _collection, ticket.ticketId, ticket.toMap());
  }

  Future<TicketModel?> getTicket(String ticketId) async {
    DocumentSnapshot doc =
        await _firestoreService.getDocument(_collection, ticketId);
    if (doc.exists) {
      return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // In ticket_service.dart
  Future<void> bindTicketToUser(String ticketId, String userId) async {
    // First check if ticket exists and is not already bound
    final ticket = await getTicket(ticketId);
    if (ticket == null) {
      throw Exception('Ticket not found');
    }

    if (ticket.userId != null && ticket.userId.isNotEmpty) {
      throw Exception('Ticket is already bound to a user');
    }

    // Update only the userId field
    await _firestoreService
        .updateDocument(_collection, ticketId, {'userId': userId});
  }

  Future<void> updateTicketValidity(String ticketId, bool isValid) async {
    await _firestoreService
        .updateDocument(_collection, ticketId, {'isValid': isValid});
  }

  /// Updates specific fields of a ticket document in Firestore.
  ///
  /// Only allows updating of specific fields:
  /// - isValid: boolean value indicating ticket validity
  /// - missedQueue: integer value tracking missed queues
  /// - ridesQueued: integer value tracking current queued rides
  ///
  /// Throws an exception if:
  /// - The ticket doesn't exist
  /// - The updates map contains fields other than the allowed ones
  /// - The field values are of incorrect type
  Future<void> updateTicket(
      String ticketId, Map<String, dynamic> updates) async {
    // First check if ticket exists
    final ticket = await getTicket(ticketId);
    if (ticket == null) {
      throw Exception('Ticket not found');
    }

    // Validate that only allowed fields are being updated
    final allowedFields = {'isValid', 'missedQueue', 'ridesQueued'};
    final updateFields = updates.keys.toSet();
    final invalidFields = updateFields.difference(allowedFields);

    if (invalidFields.isNotEmpty) {
      throw Exception(
          'Invalid fields in update: $invalidFields. Only ${allowedFields.join(", ")} can be updated.');
    }

    // Validate field types
    updates.forEach((key, value) {
      switch (key) {
        case 'isValid':
          if (value is! bool) {
            throw Exception('isValid must be a boolean');
          }
          break;
        case 'missedQueue':
        case 'ridesQueued':
          if (value is! int) {
            throw Exception('$key must be an integer');
          }
          break;
      }
    });

    // Proceed with update if all validations pass
    await _firestoreService.updateDocument(_collection, ticketId, updates);
  }

  Future<void> deleteTicket(String ticketId) async {
    await _firestoreService.deleteDocument(_collection, ticketId);
  }

  Stream<List<TicketModel>> getTicketsForEvent(String eventId) {
    return _firestoreService.getDocuments(_collection, filters: [
      QueryFilter('eventId', eventId)
    ]).map((snapshot) => snapshot.docs
        .map((doc) =>
            TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<int> getRidesQueued(String userId) async {
    try {
      final ticket = await getTicketByUserId(userId);
      return ticket?.ridesQueued ?? 0;
    } catch (e) {
      print('Error getting rides queued: $e');
      return 0;
    }
  }

  Future<int> getMissedQueue(String userId) async {
    try {
      final ticket = await getTicketByUserId(userId);
      return ticket?.missedQueue ?? 0;
    } catch (e) {
      print('Error getting missed queues: $e');
      return 0;
    }
  }

  /// Updates the ridesQueued count for a ticket
  /// [change] can be +1 (when queuing) or -1 (when dequeuing)
  Future<void> updateRidesQueued(String ticketId, int change) async {
    try {
      final ticket = await getTicket(ticketId);
      if (ticket == null) {
        throw Exception('Ticket not found');
      }

      final currentRidesQueued = ticket.ridesQueued;
      final newRidesQueued = currentRidesQueued + change;

      // Ensure rides queued doesn't go below 0
      if (newRidesQueued < 0) {
        throw Exception('Cannot reduce rides queued below 0');
      }

      // Update the rides queued count
      await updateTicket(ticketId, {'ridesQueued': newRidesQueued});
    } catch (e) {
      print('Error updating rides queued: $e');
      throw e;
    }
  }

  /// Finds a ticket associated with a specific user ID.
  /// Returns the first valid ticket found or null if no valid ticket exists.
  /// A valid ticket must have:
  /// - Matching userId
  /// - isValid = true
  /// - Not expired (expirationTime > current time)
  Future<TicketModel?> getTicketByUserId(String userId) async {
    try {
      final querySnapshot = await _firestoreService
          .queryDocuments(_collection, [QueryFilter('userId', userId)]);

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final now = DateTime.now();
      final tickets = querySnapshot.docs
          .map((doc) =>
              TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((ticket) => ticket.expirationTime.isAfter(now))
          .toList();

      return tickets.isEmpty ? null : tickets.first;
    } catch (e) {
      print('Error getting ticket by userId: $e');
      return null;
    }
  }
}
