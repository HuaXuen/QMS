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
    try {
      String? fetchedUsername = await _userService.getUsername();
      if (fetchedUsername != null) {
        _name = fetchedUsername;
        notifyListeners(); // Notify listeners of state change
      }
    } catch (e) {
      print("Failed to get username: $e");
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
}
