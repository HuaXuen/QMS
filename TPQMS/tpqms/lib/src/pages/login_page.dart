import 'package:flutter/material.dart';
import 'package:tpqms/src/authentication/phonenumber_verification_page.dart';
import 'package:tpqms/src/utilities/assets_manager.dart';

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
                        Color(0xFF0E1320).withOpacity(0.7),
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
                            color: Colors.white.withOpacity(0.1), // Glow color
                            spreadRadius: 0.001, // How far the glow spreads
                            blurRadius: 30, // Softness of the glow
                            offset: Offset(0, 0), // Centered glow
                          ),
                        ],
                      ),
                      child: Image.asset(
                        AssetsManager.tpqmsIcon,
                        fit: BoxFit.contain,
                        color: Color(0xFF8B5CF6), // Purple accent color
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
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PhoneNumberVerificationPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_iphone, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Sign in with OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Color(0xFF8B5CF6), // Purple accent color
                        elevation: 0,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    SizedBox(height: 16), // Add space between buttons
                    OutlinedButton(
                      onPressed: () {
                        // TODO: Implement admin sign in logic
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Color(0xFF8B5CF6)),
                          SizedBox(width: 12),
                          Text(
                            'Sign in as Admin',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF8B5CF6),
                        side: BorderSide(color: Color(0xFF8B5CF6)),
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
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
