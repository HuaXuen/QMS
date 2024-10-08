import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/pages/authentication/login_page.dart';
import 'package:tpqms/src/utilities/assets_manager.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Aligns children to the center
        crossAxisAlignment:
            CrossAxisAlignment.center, // Centers children horizontally
        children: [
          Lottie.asset(AssetsManager.loadingScreen), // Adjust size as needed
          const Text(
            "Loading...",
            style: TextStyle(
              color: Constants.white,
              fontSize: 24,
              fontWeight: FontWeight.bold, // Adjust color as needed
            ),
          ),
        ],
      ),
      splashIconSize: 400, // Adjust the size of the splash area as needed
      backgroundColor: Constants.primaryBackground,
      nextScreen: const LoginPage(),
    );
  }
}




// class LoadingScreen extends StatefulWidget {
//   const LoadingScreen({super.key});

//   @override
//   State<LoadingScreen> createState() => _LoadingScreenState();
// }

// class _LoadingScreenState extends State<LoadingScreen> {
//   void initState() {
//     super.initState();
//     startTimer();
//   }

//   startTimer() {
//     var duration = Duration(seconds: 4);
//     return Timer(duration, route);
//   }

//   route() {
//     Navigator.pushReplacementNamed(context, '/welcome');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: content(),
//     );
//   }

//   Widget content() {
//     return Center(
//       child: Container(
//         child: Lottie.asset(AssetsManager.loadingScreen),
//       ),
//     );
//   }
// }

//body: Center(
//   child: Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       SizedBox(
//         height: 500,
//         width: 500,
//         child: Lottie.asset(AssetsManager.loadingScreen),
//       ),
//       Text(
//         "Loading...",
//         style: TextStyle(
//           fontSize: 15,
//         ),
//       ),
//     ],
//   ),
// ),


// class _LoadingScreenState extends State<LoadingScreen> {
//   late VideoPlayerController _controller;
//   @override
//   void initState() {
//     super.initState();

//     _controller = VideoPlayerController.asset('assets/lottie/loading.mp4')
//       ..initialize().then((_) {
//         setState(() {});
//       });
//     _playVideo();
//   }

//   void _playVideo() async {
//     _controller.play();
//     //add delay till video is complete
//     await Future.delayed(const Duration(seconds: 4));
//     Navigator.pushNamed(context, '/');
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }