import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; //appcheck
import 'package:provider/provider.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/src/pages/authentication/adminverification_page.dart';
import 'package:tpqms/src/pages/authentication/otp_page.dart';
import 'package:tpqms/src/pages/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/pages/authentication/userinformation_page.dart';
import 'package:tpqms/src/pages/loading_screen.dart';
import 'package:tpqms/src/pages/users/home_page/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tpqms/src/pages/authentication/login_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/src/pages/admin/ride_management/ridemanagement_page.dart';
import 'package:tpqms/src/providers/auth_providers/authentication_provider.dart';
import 'package:tpqms/src/providers/auth_providers/session_provider.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
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

  // await FirebaseAppCheck.instance.activate(
  //   // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
  //   // argument for `webProvider`
  //   webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  //   // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Safety Net provider
  //   // 3. Play Integrity provider
  //   androidProvider: AndroidProvider.debug,
  //   // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Device Check provider
  //   // 3. App Attest provider
  //   // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
  //   appleProvider: AppleProvider.appAttest,
  // );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  final RealtimeDbService _dbService = RealtimeDbService();
  final RideService _rideService = RideService(_dbService);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_) => SessionManagerProvider(),
    ),

    // Dependent providers
    // ChangeNotifierProxyProvider<SessionManagerProvider, AuthenticationProvider>(
    //   create: (_) =>
    //       AuthenticationProvider(), // SESSION SessionManagerProvider()
    //   update: (_, sessionManager, authProvider) =>
    //       authProvider ?? AuthenticationProvider(sessionManager),
    // ),

    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => UserInfoProvider()),
    ChangeNotifierProvider(
      create: (_) => RideProvider(_rideService, _dbService),
      lazy: false,
    ),
    ChangeNotifierProvider(create: (_) => ImageProviderService()),
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
        initialRoute: Constants.LoadingScreen,
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
