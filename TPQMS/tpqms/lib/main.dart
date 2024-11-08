import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/services/ride_service.dart';
import 'package:tpqms/src/pages/authentication/adminverification_page.dart';
import 'package:tpqms/src/pages/authentication/otp_page.dart';
import 'package:tpqms/src/pages/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/pages/authentication/userinformation_page.dart';
import 'package:tpqms/src/pages/loading_screen.dart';
import 'package:tpqms/src/pages/users/landing_page/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tpqms/src/pages/authentication/login_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/src/pages/admin/ride_management/ridemanagement_page.dart';
import 'package:tpqms/src/providers/auth_providers/authentication_provider.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/ride_provider.dart';
import 'package:tpqms/services/realtimedb_service.dart';
import 'src/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tpqms/src/pages/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure plugin services are initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // Use the auto-generated options
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  final RealtimeDbService _dbService = RealtimeDbService();
  final RideService _rideService = RideService(_dbService);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => UserInfoProvider()),
    ChangeNotifierProvider(
      create: (_) => RideProvider(_rideService),
      lazy: false,
    ),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Constants.HomePage,
        routes: {
          Constants.LoadingScreen: (context) => const LoadingScreen(),
          Constants.LoginPage: (context) => const LoginPage(),
          Constants.AdminLoginPage: (context) => const AdminLoginPage(),
          Constants.PhoneNumberVerificationPage: (context) =>
              const PhoneNumberVerificationPage(),
          Constants.OtpPage: (context) => const OTPPage(),
          Constants.QrScannerPage: (context) => const QrScannerPage(),
          Constants.HomePage: (context) => const HomePage(),
          Constants.UserInformationPage: (context) =>
              const UserInformationPage(),
          Constants.RideManagementPage: (context) => const RideManagementPage(),
        });
  }
}
