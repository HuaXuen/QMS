import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/global_methods.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';

class UserInfoProvider extends ChangeNotifier {
  String? _uid;
  String? _name;
  String? _phoneNumber;
  String? _age;
  String? _height;
  UserModel? _currentUser;

  //bool? _isOnline;
  //UserModel? _userModel;

  String? get uid => _uid;
  String? get name => _name;
  String? get phoneNumber => _phoneNumber;
  String? get age => _age;
  String? get height => _height;
  bool? get isOnline => isOnline;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService(FirestoreService());
  final bool online = true;

  void setCurrentUser(UserModel user) {
    _uid = user.uid;
    _name = user.name;
    _phoneNumber = user.phoneNumber;
    _age = user.age;
    _height = user.height;
    notifyListeners();
  }

  Future<UserModel?> addUserToFirestore({
    required String uid,
    required String name,
    required String phoneNumber,
    required String age,
    required String height,
    required bool isOnline,
    required BuildContext context,
  }) async {
    print('adding user...');

    _uid = uid;
    _name = name;
    _phoneNumber = phoneNumber;
    _age = age;
    _height = height;
    //_isOnline = online;

    UserModel user = UserModel(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        age: age,
        height: height,
        isOnline: online);

    Map<String, dynamic> userData = await user.toMap();
    try {
      await _firestoreService.addDocument(Constants.users, uid, userData);
      notifyListeners(); // Notify listeners of state change
      return user;
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> fetchUsername() async {
    if (_name != null) return; // Use cached data if available

    try {
      String? fetchedUsername = await _userService.getUsername();
      if (fetchedUsername != null) {
        _name = fetchedUsername;
        notifyListeners();
      }
    } catch (e) {
      print("Failed to get username: $e");
    }
  }

  Future<void> updateUserInfo({
    String? name,
    String? age,
    String? height,
    required BuildContext context,
  }) async {
    try {
      // Only update fields that are provided
      Map<String, dynamic> updates = {};
      if (name != null) updates[Constants.name] = name;
      if (age != null) updates[Constants.age] = age;
      if (height != null) updates[Constants.height] = height;

      // Get current user's UID
      if (_uid == null) {
        throw Exception('No user is currently logged in');
      }

      // Update Firestore
      await _firestoreService.updateDocument(
        Constants.users,
        _uid!,
        updates,
      );

      // Update local state
      if (name != null) _name = name;
      if (age != null) _age = age;
      if (height != null) _height = height;

      notifyListeners();
    } catch (e) {
      print('Error updating user info: $e');
      throw e; // Rethrow to handle in UI
    }
  }

  Future<String?> getHeight() async {
    try {
      String? fetchedHeight = await _userService.getHeight();
      if (fetchedHeight != null) {
        _height = fetchedHeight;
        notifyListeners(); // Notify listeners of state change
        return fetchedHeight;
      }
      return null;
    } catch (e) {
      print("Failed to get height: $e");
      return null;
    }
  }

//here?
  Future<bool> validateUsername(String username) async {
    try {
      bool isTaken = await _userService.checkIfUsernameTaken(username);
      // Optionally, store the result or update state
      if (isTaken) {
        print("Username is already taken.");
      } else {
        print("Username is available.");
      }

      return isTaken; // Return the result to the frontend
    } catch (e) {
      print("Failed to validate username: $e");
      return false; // Return false if an error occurs
    }
  }

  // void reset() {
  //   _uid = null;
  //   _name = null;
  //   _phoneNumber = null;
  //   _age = null;
  //   _height = null;
  //   notifyListeners();
  // }

  // Example for RideProvider
  Future<void> reset() async {
    try {
      print('[RIDE-PROVIDER] Starting reset...');

      _uid = null;
      _name = null;
      _phoneNumber = null;
      _age = null;
      _height = null;
      notifyListeners();

      // Notify listeners AFTER cleanup
      notifyListeners();

      print('[RIDE-PROVIDER] Reset completed');
    } catch (e) {
      print('[RIDE-PROVIDER] Error during reset: $e');
    }
  }
}
