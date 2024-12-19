import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_buttons.dart';
import 'package:tpqms/src/pages/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/src/pages/users/qr_scanner/qrscanner_page.dart';
import 'package:tpqms/utilities/assets_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double _opacity = 0.0; // Initial opacity is 0 (invisible)

  @override
  void initState() {
    super.initState();
    // Trigger the fade-in animation after a small delay
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _opacity = 1.0; // Change the opacity to 1 (fully visible)
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: Color(0xFF0E1320), // Dark background color
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 3,
              child: ClipPath(
                clipper: CurvedBottomClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(AssetsManager.homeScreen),
                      colorFilter: ColorFilter.mode(
                        Constants.primaryBackground.withOpacity(0.7),
                        BlendMode.srcOver,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Constants.white.withOpacity(0.1), // Glow color
                            spreadRadius: 0.001, // How far the glow spreads
                            blurRadius: 30, // Softness of the glow
                            offset: Offset(0, 0), // Centered glow
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AssetsManager.tpqmsIcon,
                        fit: BoxFit.contain,
                        color: Constants.purple, // Purple accent color
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _opacity,
                      duration: Duration(seconds: 3),
                      child: Container(
                        child: Text(
                          'Welcome to TPQMS!',
                          style: TextStyle(
                            color: Constants.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    CustomElevatedButtonwithIcon(
                      text: 'Log In',
                      icon: Icons.login,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: Constants.purple,
                      foregroundColor: Constants.white,
                    ),
                    SizedBox(height: 16),
                    CustomElevatedButtonwithIcon(
                      text: 'Sign up with Phone Number',
                      icon: Icons.phone_iphone,
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PhoneNumberVerificationPage(),
                          ),
                        );
                      },
                      backgroundColor: Constants.purple,
                      foregroundColor: Constants.white,
                    ),
                    SizedBox(height: 16), // Add space between buttons
                    CustomOutlinedButtonwithIcon(
                      text: 'Sign in as Admin',
                      icon: Icons.admin_panel_settings,
                      onPressed: () {
                        // TODO: Implement admin sign in logic
                      },
                      primaryColor: Constants.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 7);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 155);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
