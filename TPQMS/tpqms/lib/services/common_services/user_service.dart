import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/model/user_model.dart';

class UserService {
  final FirestoreService _firestoreService;

  UserService(this._firestoreService);

  Future<bool> checkUserExistsByPhone(
      String collection, String phoneNumber) async {
    try {
      final querySnapshot = await _firestoreService.queryDocuments(
          collection, [QueryFilter('phoneNumber', phoneNumber)]);

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if phone exists: $e');
      return false;
    }
  }

//newly created method to be called in provider
  Future<bool> checkIfUsernameTaken(String username) async {
    try {
      final querySnapshot = await _firestoreService
          .queryDocuments('users', [QueryFilter('name', username)]);
      print(querySnapshot);
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<String?> getUidByPhoneNumber(
      String collection, String phoneNumber) async {
    try {
      final querySnapshot = await _firestoreService.queryDocuments(
          collection, [QueryFilter('phoneNumber', phoneNumber)]);

      if (querySnapshot.docs.isNotEmpty) {
        // Return the uid field from the first matching document
        return querySnapshot.docs.first.get('uid') as String?;
      }
      return null;
    } catch (e) {
      print('Error getting UID by phone number: $e');
      return null;
    }
  }

  Future<UserModel?> getUserData(String collection, String documentId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestoreService.getDocument(collection, documentId);
      if (documentSnapshot.exists) {
        return UserModel.fromMap(
            documentSnapshot.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<String?> getUsername() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String uid = currentUser.uid;

        // Fetch the user data from Firestore using the uid
        DocumentSnapshot documentSnapshot =
            await _firestoreService.getDocument(Constants.users, uid);

        if (documentSnapshot.exists) {
          // Use UserModel.fromMap to convert the data to a UserModel instance
          UserModel user = UserModel.fromMap(
              documentSnapshot.data() as Map<String, dynamic>);
          print("username: ${user.name}");
          return user.name; // Access the name property of the UserModel
        }
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<String?> getCurrentUserUid() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        return currentUser.uid; // Directly fetch the authenticated user's UID
      }
      return null;
    } catch (e) {
      print('Error getting current user UID: $e');
      return null;
    }
  }
}
