import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/src/authentication/otp_page.dart';
import 'package:tpqms/src/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/src/constants.dart';
import 'package:tpqms/src/pages/loading_screen.dart';
import 'package:tpqms/src/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tpqms/src/pages/login_page.dart';
import 'package:tpqms/src/providers/authentication_provider.dart';
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
    //ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        // title: 'Flutter TPQMS',
        // theme: ThemeData(
        //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        //   useMaterial3: true,
        // ),
        initialRoute: Constants.loginPage,
        routes: {
          Constants.loginPage: (context) => const LoginPage(),
          Constants.PhoneNumberVerificationPage: (context) =>
              const PhoneNumberVerificationPage(),
          Constants.otpPage: (context) => const OTPPage(),
          Constants.homePage: (context) => const HomePage(),
        });
  }
}
