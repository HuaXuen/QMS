import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/common/global_methods.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/services/firestore_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _hasAttemptedVerification = false;
  String? _uid;
  String? _name;
  String? _phoneNumber;
  String? _age;
  String? _height;
  UserModel? _userModel;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  bool get hasAttemptedVerification => _hasAttemptedVerification;
  String? get uid => _uid;
  String? get phonenumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Navigation navigation = Navigation();

  get currentUser => null;

  //check if user exists
  Future<bool> checkUserExists() async {
    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constants.users).doc(_uid).get();
    if (documentSnapshot.exists) {
      print('User document found in Firestore: ${documentSnapshot.data()}');

      return true;
    } else {
      print('User document not found in Firestore.');

      return false;
    }
  }

  //get user data from firestore
  Future<void> getUserData() async {
    DocumentSnapshot documentSnapshot =
        await _firestoreService.getDocument(Constants.users, _uid!);
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
    print('Before calling verifyPhoneNumber');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Verification completed with credential: $credential');
          await _auth.signInWithCredential(credential).then((value) async {
            _uid = value.user?.uid;
            _phoneNumber = value.user?.phoneNumber;

            _isSuccessful = true;
            _isLoading = false;
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
          print('Code sent. Verification ID: $verificationId');
          _isLoading = false;
          notifyListeners();

          Navigator.of(context).pushNamed(
            Constants.OtpPage,
            arguments: {
              Constants.verificationId: verificationId,
              Constants.phoneNumber: phoneNumber,
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto-retrieval timeout: $verificationId');
        },
      );
    } catch (e) {
      print('Error during signInWithPhoneNumber: $e');
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
    //required Function onSuccess,
  }) async {
    print('Attempting to verify OTP');

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
      print('OTP verified successfully. User signed in.');

      print('UID assigned: $_uid');
      print('Phone number assigned: $_phoneNumber');
      bool userExists = await checkUserExists();
      if (userExists) {
        //get info from firestore
        await getUserData();
        //navigate to home screen
        navigation.handleUserLoginNavigation(
          userExists: true,
          context: context,
          uid: uid!,
          phoneNumber: '$_phoneNumber',
        );
      } else {
        print('uID assigned: $_uid');
        print('Phone number assigned: $_phoneNumber');
        navigation.handleUserLoginNavigation(
          userExists: false,
          context: context,
          uid: uid!,
          phoneNumber: '$_phoneNumber',
        );
      }
      _isSuccessful = true;
      _isLoading = false;
      //onSuccess();
      notifyListeners();
    }).catchError((e) {
      _isSuccessful = false;
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    });
  }

  //void saveUserDataToFirestore({required UserModel userModel})
}
