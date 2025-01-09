import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; //appcheck
import 'package:provider/provider.dart';
import 'package:tpqms/services/admin_services/admin_auth_service.dart';
import 'package:tpqms/services/admin_services/admin_ride_service.dart';
import 'package:tpqms/services/common_services/location_service.dart';
import 'package:tpqms/services/common_services/notification_service.dart';
import 'package:tpqms/services/common_services/queue_service.dart';
import 'package:tpqms/services/common_services/ride_service.dart';
import 'package:tpqms/services/common_services/ticket_service.dart';
import 'package:tpqms/services/common_services/user_service.dart';
import 'package:tpqms/services/firebase_services/firestore_service.dart';
import 'package:tpqms/src/pages/authentication/adminlogin_page.dart';
import 'package:tpqms/src/pages/authentication/otp_page.dart';
import 'package:tpqms/src/pages/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/pages/authentication/user_account_creation_page.dart';
import 'package:tpqms/src/pages/loading_screen.dart';
import 'package:tpqms/src/pages/users/home_page/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tpqms/src/pages/authentication/login_page.dart';
import 'package:tpqms/src/pages/users/profile/profile_page.dart';
import 'package:tpqms/src/pages/users/queue_page/queue_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/src/pages/admin/ride_management/add_ride_page.dart';
import 'package:tpqms/src/providers/admin_providers/admin_auth_provider.dart';
import 'package:tpqms/src/providers/admin_providers/admin_ride_analytics_provider.dart';
import 'package:tpqms/src/providers/admin_providers/admin_ride_provider.dart';
import 'package:tpqms/src/providers/auth_providers/authentication_provider.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/common_providers/image_provider.dart';
import 'package:tpqms/src/providers/user_providers/location_provider.dart';
import 'package:tpqms/src/providers/user_providers/queue_provider.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';
import 'package:tpqms/services/firebase_services/realtimedb_service.dart';
import 'package:tpqms/src/providers/user_providers/ticket_provider.dart';
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
  final FirestoreService _firestoreService = FirestoreService();
  final QueueService _queueService = QueueService(_dbService, _rideService);
  final TicketService _ticketService = TicketService(_firestoreService);
  final UserService _userService = UserService(_firestoreService);
  final NotificationService _notificationService = NotificationService();
  final AdminRideService _adminRideService = AdminRideService(
      _dbService, _firestoreService, _rideService, _notificationService);
  final AdminAuthService _adminAuthService =
      AdminAuthService(_firestoreService);
  final LocationService _locationService =
      LocationService(_notificationService);
  final LocationProvider _locationProvider =
      LocationProvider(_locationService, _rideService);
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
    ChangeNotifierProvider(create: (_) => UserInfoProvider()),
    ChangeNotifierProvider(
      create: (_) => RideProvider(_rideService, _dbService),
      lazy: false,
    ),
    ChangeNotifierProvider(create: (_) => ImageProviderService()),
    ChangeNotifierProvider(
      create: (context) =>
          TicketProvider(_ticketService, _firestoreService, _userService),
      lazy: false,
    ),
    ChangeNotifierProvider(
      create: (context) => QueueProvider(_queueService, _ticketService,
          _userService, _rideService, _notificationService, _locationProvider),
      lazy: true,
    ),
    ChangeNotifierProvider(
      create: (_) => AdminRideProvider(
        _adminRideService,
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => AdminAuthProvider(_adminAuthService),
    ),
    ChangeNotifierProvider(
      create: (context) => LocationProvider(_locationService, _rideService),
    ),
    ChangeNotifierProvider(
      create: (context) => RideAnalyticsProvider(_firestoreService),
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
          Constants.QueuePage: (context) => const QueuePage(),
          Constants.ProfilePage: (context) => const ProfilePage(),
        });
  }
}
