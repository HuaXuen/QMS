import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/providers/authentication_provider.dart';

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  State<OTPPage> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPPage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  String? otpCode;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //get the arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final verificationId = args[Constants.verificationId] as String;
    final phoneNumber = args[Constants.phoneNumber] as String;

    final _authProvider = context.watch<AuthenticationProvider>();

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.openSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade100,
        border: Border.all(
          color: Colors.red,
        ),
      ),
    );

    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  Text(
                    'OTP Verification',
                    style: GoogleFonts.openSans(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'Enter the 6-digit code sent to the number:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    phoneNumber,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: SizedBox(
                      height: 68,
                      child: Pinput(
                        length: 6,
                        controller: controller,
                        focusNode: focusNode,
                        defaultPinTheme:
                            _authProvider.hasAttemptedVerification &&
                                    !_authProvider.isSuccessful &&
                                    !_authProvider.isLoading
                                ? errorPinTheme
                                : defaultPinTheme,
                        onCompleted: (pin) {
                          setState(() {
                            otpCode = pin;
                          });
                          _authProvider.verifyOTPCode(
                              verificationId: verificationId,
                              otpCode: otpCode!,
                              context: context);
                        },
                        focusedPinTheme: defaultPinTheme.copyWith(
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.deepPurple,
                            border: Border.all(
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                        errorPinTheme: defaultPinTheme.copyWith(
                          height: 68,
                          width: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade200,
                            border: Border.all(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _authProvider.isLoading
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
                  _authProvider.isSuccessful
                      ? Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.done,
                            color: Constants.white,
                            size: 30,
                          ),
                        )
                      : const SizedBox.shrink(),
                  _authProvider.hasAttemptedVerification &&
                          !_authProvider.isSuccessful &&
                          !_authProvider.isLoading
                      ? SizedBox(
                          height: 60,
                          child: Container(
                            child: const Text(
                              "Incorrect OTP",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  _authProvider.isLoading
                      ? const SizedBox.shrink()
                      : Text(
                          'Didn\'t receive the code?',
                          style: GoogleFonts.openSans(fontSize: 16), // Text
                        ),
                  const SizedBox(height: 5),
                  TextButton(
                    onPressed: () {
                      //todo: listen otp code
                    },
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  // void verifyOTPCode({
  //   required String verificationId,
  //   required String otpCode,
  // }) async {
  //   final authProvider = context.read<AuthenticationProvider>();
  //   authProvider.verifyOTPCode(
  //       verificationId: verificationId,
  //       otpCode: otpCode,
  //       context: context,
  //       onSuccess: () async {
  //         bool userExists = await authProvider.checkUserExists();
  //         if (userExists) {
  //           //get info from firestore
  //           await authProvider.getUserData();
  //           //navigate to home screen
  //           navigate(userExists: true);
  //         } else {
  //           navigate(userExists: false);
  //         }
  //       });
  // }

  // void navigate({required bool userExists}) {
  //   //navigate to home screen
  //   if (userExists) {
  //     Navigator.pushNamedAndRemoveUntil(
  //       context,
  //       Constants.homePage,
  //       (route) => false,
  //     );
  //   } else {
  //     //navigate to
  //     Navigator.pushReplacementNamed(
  //       context,
  //       Constants.homePage,
  //     );
  //   }
  // }
}
