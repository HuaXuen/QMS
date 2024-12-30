import 'dart:ui';

import 'package:flutter/material.dart';

class Constants {
  //screen routes
  static const String LoadingScreen = '/loadingScreen';
  static const String LoginPage = '/loginPage';
  static const String PhoneNumberVerificationPage =
      '/phoneNumberVerificationPage';
  static const String OtpPage = '/otpPage';
  static const String HomePage = '/homePage';
  static const String QrScannerPage = '/qrscannerPage';
  static const String UserInformationPage = '/userInformationPage';
  static const String AdminLoginPage = '/adminLoginPage';
  static const String RideManagementPage = '/ridemManagementPage';
  static const String QueuePage = '/queuePage';
  static const String ProfilePage = '/profilePage';

// constant variables
  static const String uid = 'uid';
  static const String name = 'name';
  static const String phoneNumber = 'phoneNumber';
  static const String age = 'age';
  static const String height = 'height';
  static const String isOnline = 'isOnline';

  static const String image = 'image';
  static const String token = 'token';
  static const String validTicket = 'validTicket';

  static const String verificationId = 'verificationId';
  static const String users = 'users';
  static const String userModel = 'userModel';

//colours
  static const Color primaryBackground = Color(0xFF0E1320);
  static const Color secondaryBackground = Color(0xFF1A2235);
  static const Color homeBackground = Color(0xFF1A1A1A);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color white = Color.fromARGB(255, 255, 255, 255);
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color darkGrey = Color.fromARGB(255, 49, 49, 49);
  static const Color transparent = Colors.transparent;

  static const FontWeight bold = FontWeight.w700;

//db routes
  static const String ridesDbRoute = 'rides';
}
