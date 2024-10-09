import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInstance {
  static final FirestoreInstance _instance = FirestoreInstance._internal();
  late final FirebaseFirestore _firestore;

  factory FirestoreInstance() {
    return _instance;
  }

  FirestoreInstance._internal() {
    _firestore = FirebaseFirestore.instance;
  }

  FirebaseFirestore get firestore => _firestore;
}
