import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDocument(
      String collection, String? documentId, Map<String, dynamic> data) async {
    if (documentId != null) {
      await _firestore.collection(collection).doc(documentId).set(data);
    } else {
      await _firestore.collection(collection).add(data);
    }
  }

  Future<DocumentSnapshot> getDocument(
      String collection, String documentId) async {
    return await _firestore.collection(collection).doc(documentId).get();
  }

  Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(documentId).update(data);
  }

  Future<void> deleteDocument(String collection, String documentId) async {
    await _firestore.collection(collection).doc(documentId).delete();
  }

  Stream<QuerySnapshot> getDocuments(String collection,
      {List<QueryFilter>? filters}) {
    Query query = _firestore.collection(collection);
    if (filters != null) {
      for (var filter in filters) {
        query = query.where(filter.field, isEqualTo: filter.value);
      }
    }
    return query.snapshots();
  }
}

class QueryFilter {
  final String field;
  final dynamic value;

  QueryFilter(this.field, this.value);
}
