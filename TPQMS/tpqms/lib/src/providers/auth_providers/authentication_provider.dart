import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/common/global_methods.dart';
import 'package:tpqms/src/providers/auth_providers/session_provider.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService;
  late final UserService _userService;
  final Navigation navigation = Navigation();
  final UserInfoProvider _userInfoProvider = UserInfoProvider();
  //SEARCH SESSION TO FIND RELATED COMMENTED SESSION CODE
  //final SessionManagerProvider _sessionManager;

  //constructor
  AuthenticationProvider() //this._sessionManager SESSION
      : _firestoreService = FirestoreService() {
    _userService = UserService(_firestoreService);
  }

//prompt token check when click on 'sign in with phone number'

  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _hasAttemptedVerification = false;
  String? _uid;
  String? _name;
  String? _phoneNumber;
  String? _age;
  String? _height;
  UserModel? _userModel;
  String? _verificationId;
  int? _resendToken;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  bool get hasAttemptedVerification => _hasAttemptedVerification;
  String? get uid => _uid;
  String? get phonenumber => _phoneNumber;
  UserModel? get userModel => _userModel;

  get currentUser => null;

  //save user data to shared preferences
  Future<void> saveUserDataToSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(
        Constants.userModel, jsonEncode(userModel!.toMap()));
  }

  // void _reinitializeProviders(BuildContext context) {
  //   final userInfoProvider =
  //       Provider.of<UserInfoProvider>(context, listen: false);
  //   final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
  //   final queueProvider = Provider.of<QueueProvider>(context, listen: false);
  //   final rideProvider = Provider.of<RideProvider>(context, listen: false);

  //   // Refresh state and data for each provider
  //   userInfoProvider.fetchUsername();
  //   ticketProvider.loadTicketData();
  //   queueProvider.initializeQueueStream();
  //   rideProvider.refreshRides();

  //   print('[AUTH] Providers reinitialized for the new user.');
  // }

  //sign in with phone number
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();
    print('Before calling verifyPhoneNumber');

    try {
      bool _hasNavigatedToOTP = false;

      bool userExists = await _userService.checkUserExistsByPhone(
          Constants.users, phoneNumber);
      if (userExists) {
        print('User already exists.');
        print('${phoneNumber}');
        _uid = await _userService.getUidByPhoneNumber(
            Constants.users, phoneNumber);
        print('${_uid}');
        if (_uid != null) {
          _userModel = await _userService.getUserData(Constants.users, _uid!);
          if (_userModel != null) {
            context.read<UserInfoProvider>().setCurrentUser(_userModel!);
            // _reinitializeProviders(context);

            navigation.handleUserLoginNavigation(
                userExists: true, context: context, userModel: _userModel);
          } else {
            throw Exception('Failed to load user data');
          }
        } else {
          throw Exception('Failed to get user ID');
        }
      } else {
        print('User does not exist.');
        await FirebaseAuth.instance
            .setSettings(appVerificationDisabledForTesting: false);

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
            _isSuccessful = true;
            _isLoading = false;
            notifyListeners();

            // Avoid duplicate navigation
            if (!_hasNavigatedToOTP) {
              Navigator.of(context).pushNamed(
                Constants.OtpPage,
                arguments: {
                  Constants.verificationId: verificationId,
                  Constants.phoneNumber: phoneNumber,
                },
              );
              _hasNavigatedToOTP = true;

              //onSuccess();
              notifyListeners();
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            print('Code auto-retrieval timeout');
            _verificationId = verificationId;
          },
          //forceResendingToken: _resendToken,
        );
      }
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
  }) async {
    print('Attempting to verify OTP');

    _hasAttemptedVerification = true;
    _isLoading = true;
    notifyListeners();

    try {
      // First, verify the OTP credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Get user information after successful OTP verification
      _uid = userCredential.user!.uid;
      _phoneNumber = userCredential.user!.phoneNumber;
      print('OTP verified successfully. User signed in.');
      print('UID assigned: $_uid');
      print('Phone number assigned: $_phoneNumber');

      // Now check if user exists in Firestore
      if (_phoneNumber != null) {
        bool userExists = await _userService.checkUserExistsByPhone(
            Constants.users, _phoneNumber!);

        if (userExists) {
          print('Existing user detected after OTP verification');
          // Get user data and navigate to home
          _userModel = await _userService.getUserData(Constants.users, _uid!);

          if (_userModel != null) {
            // Set current user in UserInfoProvider before navigation
            context.read<UserInfoProvider>().setCurrentUser(_userModel!);
            //_reinitializeProviders(context);

            // Navigate to home page for existing user
            navigation.handleUserLoginNavigation(
                userExists: true, context: context, userModel: _userModel);
          } else {
            throw Exception('Failed to load user data');
          }
        } else {
          print('New user detected after OTP verification');
          // Navigate to user information page for new user
          navigation.navigateToUserInformation(
              context: context, uid: _uid!, phoneNumber: _phoneNumber!);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error during OTP verification: $e');
      _isSuccessful = false;
      _isLoading = false;
      notifyListeners();
      showSnackBar(context, e.toString());
    }
  }
  // Future<void> resendOTP({
  //   required String phoneNumber,
  //   required BuildContext context,
  // }) async {
  //   // Ensure that the resend OTP process only begins if the resendToken is valid.
  //   if (_resendToken != null) {
  //     print('Attempting to resend OTP...');

  //     _isLoading = true;
  //     notifyListeners();

  //     try {
  //       await _auth.verifyPhoneNumber(
  //         phoneNumber: phoneNumber,
  //         timeout: const Duration(seconds: 60),
  //         forceResendingToken: _resendToken,
  //         verificationCompleted: (PhoneAuthCredential credential) async {
  //           // This callback is called automatically when the verification is completed successfully.
  //           print('Verification completed with credential: $credential');

  //           await _auth.signInWithCredential(credential).then((value) async {
  //             _uid = value.user?.uid;
  //             _phoneNumber = value.user?.phoneNumber;

  //             final String? idToken = await _auth.currentUser?.getIdToken();
  //             if (idToken != null) {
  //               await _sessionManager.saveSession(idToken);
  //               print('Session saved successfully.');
  //             }

  //             // Successful navigation after verification.
  //             navigation.navigateToUserInformation(
  //               context: context,
  //               uid: _uid!,
  //               phoneNumber: _phoneNumber!,
  //             );

  //             _isSuccessful = true;
  //             _isLoading = false;
  //             notifyListeners();
  //           });
  //         },
  //         verificationFailed: (FirebaseAuthException e) {
  //           // This callback is called if verification fails.
  //           print('Verification failed: ${e.message}');
  //           _isSuccessful = false;
  //           _isLoading = false;
  //           notifyListeners();
  //           showSnackBar(context, 'Verification failed: ${e.message}');
  //         },
  //         codeSent: (String verificationId, int? resendToken) async {
  //           // This callback is called after the OTP is successfully sent.
  //           print('Resent code sent. Verification ID: $verificationId');
  //           _verificationId = verificationId;
  //           _resendToken = resendToken;

  //           _isLoading = false;
  //           notifyListeners();
  //         },
  //         codeAutoRetrievalTimeout: (String verificationId) {
  //           // Timeout callback, sets the verificationId for manual verification.
  //           print('Resent code auto-retrieval timeout');
  //           _verificationId = verificationId;
  //         },
  //       );
  //     } catch (e) {
  //       // General catch for any unexpected errors during the resend process.
  //       print('Error during resendOTP: $e');
  //       _isLoading = false;
  //       notifyListeners();
  //       showSnackBar(context, 'Error while resending OTP: $e');
  //     }
  //   } else {
  //     // If _resendToken is null, the OTP resend cannot proceed.
  //     print('Resend token is null. Cannot resend OTP at this time.');
  //     showSnackBar(context, 'Cannot resend OTP at this time.');
  //   }
  // }

  Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    try {
      _isLoading = true;
      notifyListeners();

      print('[AUTH] Starting coordinated logout sequence...');

      // 1. First stop all active listeners/streams
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final userInfoProvider =
          Provider.of<UserInfoProvider>(context, listen: false);

      // 2. Cancel any active subscriptions/listeners
      print('[AUTH] Canceling active subscriptions...');
      await Future.wait<void>([
        rideProvider.reset(),
        queueProvider.reset(),
        ticketProvider.reset(),
        userInfoProvider.reset()
      ]);

      // // 3. Clear persistent storage
      // print('[AUTH] Clearing persistent storage...');
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();

      // 4. Sign out from Firebase
      print('[AUTH] Signing out from Firebase...');
      await _auth.signOut();

      // 5. Clear local state
      print('[AUTH] Clearing local state...');
      _clearLocalState();

      // 6. Navigate only if context is still valid
      if (context.mounted) {
        print('[AUTH] Navigating to login...');
        await Navigator.of(context).pushNamedAndRemoveUntil(
          Constants.LoginPage,
          (route) => false,
        );
      }

      print('[AUTH] Logout sequence completed successfully');
    } catch (e) {
      print('[AUTH] Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Helper to clear local state
  void _clearLocalState() {
    _uid = null;
    _name = null;
    _phoneNumber = null;
    _userModel = null;
    _isSuccessful = false;
    _hasAttemptedVerification = false;
    _verificationId = null;
    _resendToken = null;
  }
  //void saveUserDataToFirestore({required UserModel userModel})
}
