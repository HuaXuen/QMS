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

  List<String> generateChildrenIds(int numOfChildren, String parentId) {
    List<String> childrenIds = List.generate(numOfChildren, (index) {
      return '$parentId-child${index + 1}'; // Concatenate parentId with child index
    });
    return childrenIds;
  }

  Future<void> updateChildId(
      String ticketId, String childId, Map<String, dynamic> childData) async {
    try {
      // Access the children sub-collection under the specified ticket
      await _firestoreService.addDocument(
        'tickets/$ticketId/children', // Path to the children sub-collection
        childId, // Document ID for the child
        childData, // Data for the child document
      );
      print('Child document updated successfully: $childId');
    } catch (e) {
      print('Error updating child document: $e');
      rethrow;
    }
  }

  Future<TicketModel?> getTicket(String ticketId) async {
    DocumentSnapshot doc =
        await _firestoreService.getDocument(_collection, ticketId);
    if (doc.exists) {
      return TicketModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateTicketValidity(String ticketId, bool isValid) async {
    await _firestoreService
        .updateDocument(_collection, ticketId, {'isValid': isValid});
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
}
