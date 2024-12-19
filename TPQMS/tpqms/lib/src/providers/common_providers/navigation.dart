import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/src/pages/users/ride_details/ride_details.dart';

class Navigation {
  void handleUserLoginNavigation({
    required bool userExists,
    required BuildContext context,
    required UserModel? userModel,
  }) {
    if (userExists && userModel != null) {
      print("User logged in: ${userModel.uid}, ${userModel.phoneNumber}");
      Navigator.pushNamedAndRemoveUntil(
        context,
        Constants.HomePage,
        (route) => false,
        arguments: userModel,
      );
    } else {
      // If user doesn't exist or userModel is null, navigate to user information page
      // with minimal required data
      Navigator.of(context).pushReplacementNamed(
        Constants.UserInformationPage,
        arguments: userModel,
      );
    }
  }

  void navigateToHome({
    required BuildContext context,
    required UserModel? userModel,
  }) {
    Navigator.of(context).pushReplacementNamed(
      Constants.HomePage,
      arguments: userModel!,
    );
  }

  void navigateToUserInformation({
    required BuildContext context,
    required String? uid,
    required String? phoneNumber,
  }) {
    Navigator.of(context).pushReplacementNamed(
      Constants.UserInformationPage,
      arguments: {
        Constants.uid: uid ?? '',
        Constants.phoneNumber: phoneNumber ?? '',
      },
    );
  }

  // void navigateToRidePopUp(
  //     {required BuildContext context, required RideModel? rideModel}) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => RideDetailsPage(rideData: rideModel!),
  //     ),
  //   );
  // }

  void navigateToRideDetails({
    required BuildContext context,
    required RideModel? rideModel,
    required String folderPath,
    required String imagePath,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailsPage(
          ride: rideModel!,
          folderPath: folderPath,
          imagePath: imagePath,
        ),
      ),
    );
  }
}
