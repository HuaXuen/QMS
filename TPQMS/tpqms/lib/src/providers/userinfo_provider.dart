import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/common/global_methods.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/src/services/firestore_service.dart';

class UserInfoProvider extends ChangeNotifier {
  String? _uid;
  String? _name;
  String? _phoneNumber;
  String? _age;
  String? _height;
  //UserModel? _userModel;

  String? get uid => _uid;
  String? get name => _name;
  String? get phoneNumber => _phoneNumber;
  String? get age => _age;
  String? get height => _height;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addUserToFirestore({
    required String uid,
    required String name,
    required String phoneNumber,
    required String age,
    required String height,
    required BuildContext context,
  }) async {
    print('adding user...');

    // Set the internal state
    _uid = uid;
    _name = name;
    _phoneNumber = phoneNumber;
    _age = age;
    _height = height;

    UserModel user = UserModel(
        uid: uid,
        name: name,
        phoneNumber: phoneNumber,
        age: age,
        height: height);

    Map<String, dynamic> userData = await user.toMap();
    try {
      await _firestoreService.addDocument(Constants.users, uid, userData);
      notifyListeners(); // Notify listeners of state change
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
