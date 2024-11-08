import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';

class Navigation {
  void handleUserLoginNavigation({
    required bool userExists,
    required BuildContext context,
    required String uid,
    required String phoneNumber,
  }) {
    //navigate to home screen
    if (userExists) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Constants.HomePage,
        (route) => false,
      );
    } else {
      //navigate to
      Navigator.of(context)
          .pushReplacementNamed(Constants.UserInformationPage, arguments: {
        Constants.uid: uid,
        Constants.phoneNumber: phoneNumber,
      });
    }
  }

  void navigateToHome(
      {required BuildContext context,
      required String uid,
      required String phoneNumber}) {
    Navigator.of(context)
        .pushReplacementNamed(Constants.UserInformationPage, arguments: {
      Constants.uid: uid,
      Constants.phoneNumber: phoneNumber,
    });
  }
}
