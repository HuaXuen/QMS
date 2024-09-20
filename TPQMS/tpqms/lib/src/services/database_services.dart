import 'package:cloud_firestore/cloud_firestore.dart';

const String TODO_COLLECTION_REF = "users";

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;
  late final CollectionReference _todosRef;

  DatabaseService (){
  }
}