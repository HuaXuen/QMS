import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/model/ride_model.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/src/pages/users/home_page/home_page.dart';
import 'package:tpqms/src/pages/users/profile/profile_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/ticket_page.dart';
import 'package:tpqms/src/pages/users/queue_page/queue_page.dart';
import 'package:tpqms/src/pages/users/ride_details/ride_details.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart';

class Navigation {
  void handleUserLoginNavigation({
    required bool userExists,
    required BuildContext context,
    required UserModel? userModel,
  }) async {
    // Made async to handle reinitialization
    if (userExists && userModel != null) {
      print("User logged in: ${userModel.uid}, ${userModel.phoneNumber}");

      // First, reinitialize all providers before navigation
      await _reinitializeProviders(context, userModel);

      // Then navigate to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        Constants.HomePage,
        (route) => false,
        arguments: userModel,
      );
    } else {
      Navigator.of(context).pushReplacementNamed(
        Constants.UserInformationPage,
        arguments: userModel,
      );
    }
  }

// Add this method to handle provider reinitialization
  Future<void> _reinitializeProviders(
      BuildContext context, UserModel userModel) async {
    print(
        '[AUTH] Starting provider reinitialization for user: ${userModel.uid}');

    // Get provider instances
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final userInfoProvider =
        Provider.of<UserInfoProvider>(context, listen: false);

    // First cancel all existing subscriptions
    await Future.wait([
      queueProvider.reset(),
      ticketProvider.reset(),
      rideProvider.reset(),
      userInfoProvider.reset()
    ]);

    // Now initialize with new user context
    userInfoProvider.setCurrentUser(userModel);
    await queueProvider
        .initializeQueueStream(); // This will now start fresh with new user
    await ticketProvider.loadTicketData();
    await rideProvider.refreshRides();

    print('[AUTH] Provider reinitialization completed');
  }

  void navigateToHome({
    required BuildContext context,
    UserModel? userModel,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
      (route) => false,
    );
  }

  // Add this to your Navigation class
  void navigateToQueue({
    required BuildContext context,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QueuePage(),
      ),
    );
  }

  void navigateToTicket({
    required BuildContext context,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TicketPage(),
      ),
    );
  }

  void navigateToProfile({
    required BuildContext context,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilePage(),
      ),
    );
  }

  void navigateToQRScanner({
    required BuildContext context,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerPage(),
      ),
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
