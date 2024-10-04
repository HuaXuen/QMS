import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/src/providers/authentication_provider.dart';
import 'package:tpqms/src/utilities/assets_manager.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneNumberVerificationPage extends StatefulWidget {
  const PhoneNumberVerificationPage({super.key});

  @override
  State<PhoneNumberVerificationPage> createState() =>
      _PhoneNumberVerification();
}

class _PhoneNumberVerification extends State<PhoneNumberVerificationPage> {
  final TextEditingController _phoneNumberController = TextEditingController();

  Country _selectedCountry = Country(
    phoneCode: "+60",
    countryCode: "MY",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "Malaysia",
    example: "Malaysia",
    displayName: "Malaysia",
    displayNameNoCountryCode: "MY",
    e164Key: "",
  );

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _authProvider = context.watch<AuthenticationProvider>();
    //final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xFF0E1320),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 70),
              Center(
                child: Image.asset(
                  AssetsManager.tpqmsIcon,
                  height: 250,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              Text(
                "Please enter your phone number and wait for an OTP number",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1A2235),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: true,
                          countryListTheme: CountryListThemeData(
                            backgroundColor: Color(0xFF1A2235),
                            textStyle: GoogleFonts.inter(color: Colors.white),
                            bottomSheetHeight: 500,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country;
                            });
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 18),
                        child: Text(
                          '${_selectedCountry.flagEmoji} ${_selectedCountry.phoneCode}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneNumberController,
                        maxLength: 9,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: GoogleFonts.inter(color: Colors.white54),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    if (_phoneNumberController.text.length > 8)
                      _authProvider.isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF8B5CF6)),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.arrow_forward,
                                  color: Color(0xFF8B5CF6)),
                              onPressed: () {
                                _authProvider.signInWithPhoneNumber(
                                  phoneNumber:
                                      //verify phone num
                                      '${_selectedCountry.phoneCode}${_phoneNumberController.text}',
                                  context: context,
                                );
                              },
                            ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              AnimatedOpacity(
                opacity: _phoneNumberController.text.length > 8 ? 1.0 : 0.0,
                duration: Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: _phoneNumberController.text.length > 8
                      ? () {
                          print("passed 1st");

                          _authProvider.signInWithPhoneNumber(
                            //verify phone num
                            phoneNumber:
                                '${_selectedCountry.phoneCode}${_phoneNumberController.text}',
                            context: context,
                          );
                        }
                      : null,
                  child: Text(
                    'Verify Phone Number',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFF8B5CF6),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
