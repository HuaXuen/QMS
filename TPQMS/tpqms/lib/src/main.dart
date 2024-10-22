import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/src/pages/authentication/otp_page.dart';
import 'package:tpqms/src/pages/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/pages/authentication/userinformation_page.dart';
import 'package:tpqms/src/pages/loading_screen.dart';
import 'package:tpqms/src/pages/landing_page/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tpqms/src/pages/authentication/login_page.dart';
import 'package:tpqms/src/pages/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/src/providers/authentication_provider.dart';
import 'package:tpqms/src/providers/userinfo_provider.dart';
import 'firebase_options.dart';
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

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => UserInfoProvider()),
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
        // title: 'Flutter TPQMS',
        // theme: ThemeData(
        //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        //   useMaterial3: true,
        // ),
        initialRoute: Constants.LoadingScreen,
        routes: {
          Constants.LoadingScreen: (context) => const LoadingScreen(),
          Constants.LoginPage: (context) => const LoginPage(),
          Constants.PhoneNumberVerificationPage: (context) =>
              const PhoneNumberVerificationPage(),
          Constants.OtpPage: (context) => const OTPPage(),
          Constants.QrScannerPage: (context) => const QrScannerPage(),
          Constants.HomePage: (context) => const HomePage(),
          Constants.UserInformationPage: (context) =>
              const UserInformationPage(),
        });
  }
}
