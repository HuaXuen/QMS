import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/src/common/global_methods.dart';
import 'package:tpqms/src/services/firestore_instance.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _hasAttemptedVerification = false;
  String? _uid;
  String? _phoneNumber;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  bool get hasAttemptedVerification => _hasAttemptedVerification;
  String? get uid => _uid;
  String? get phonenumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirestoreInstance().firestore;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //check if user exists
  Future<bool> checkUserExists() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    if (documentSnapshot.exists) {
      return true;
    } else {
      return false;
    }
  }

  //get user data from firestore
  Future<void> getUserData() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    _userModel =
        UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
    notifyListeners();
  }

  //save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(userModel!.toMap()));
  }

  //get data from shared preferences

  //sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    print('Before await');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Verification completed');
          await _auth.signInWithCredential(credential).then((value) async {
            _uid = value.user!.uid;
            _phoneNumber = value.user!.phoneNumber;
            _isSuccessful = true;
            _isLoading = false;
            print("Verifying......");
            notifyListeners();
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          _isSuccessful = false;
          _isLoading = false;
          notifyListeners();
          showSnackBar(context, e.toString());
        },
        codeSent: (String verificationId, int? resendToken) async {
          print('Code sent');
          _isLoading = false;
          notifyListeners();
          Navigator.of(context).pushNamed(Constants.otpPage, arguments: {
            Constants.verificationId: verificationId,
            Constants.phoneNumber: phoneNumber,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto retrieval timeout');
        },
      );
    } catch (e) {
      print('Error in signInWithPhoneNumber: $e');
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    }
  }

  // verify otp code
  Future<void> verifyOTPCode({
    required String verificationId,
    required String otpCode,
    required BuildContext context,
    required Function onSuccess,
  }) async {
    _hasAttemptedVerification = true;
    _isLoading = true;
    notifyListeners();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    await _auth.signInWithCredential(credential).then((value) async {
      _uid = value.user!.uid;
      _phoneNumber = value.user!.phoneNumber;
      _isSuccessful = true;
      _isLoading = false;
      onSuccess();
      notifyListeners();
    }).catchError((e) {
      _isSuccessful = false;
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    });
  }
}
