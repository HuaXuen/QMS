import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_buttons.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popup.dart';
import 'package:tpqms/common/resuable_widgets/reusable_textfield.dart';
import 'package:tpqms/src/model/user_model.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/utilities/assets_manager.dart';

class UserInformationPage extends StatefulWidget {
  const UserInformationPage({Key? key}) : super(key: key);

  @override
  _UserInformationPageState createState() => _UserInformationPageState();
}

class _UserInformationPageState extends State<UserInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _usernameError; // Declare _usernameError to store validation error

  @override
  void dispose() {
    _usernameController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map;
    final _uid = args[Constants.uid] as String;
    final _phoneNumber = args[Constants.phoneNumber] as String;
    //final _userInfoProvider = context.watch<UserInfoProvider>();

    void _submitForm() async {
      if (_formKey.currentState!.validate()) {
        final userInfoProvider =
            Provider.of<UserInfoProvider>(context, listen: false);
        final username = _usernameController.text;
        print("uid: ${_uid}");
        print("phone: ${_phoneNumber}");
        bool isTaken = await userInfoProvider.validateUsername(username);
        if (isTaken) {
          setState(() {
            _usernameError = "This username is already taken.";
          });
          return; // Exit the function to prevent form submission
        } else {
          setState(() {
            _usernameError = null; // Clear the error if the username is valid
          });
        }

        try {
          UserModel? userModel = await userInfoProvider.addUserToFirestore(
            uid: _uid, // from arguments
            name: _usernameController.text,
            phoneNumber: _phoneNumber, // from arguments
            age: _ageController.text,
            height: _heightController.text,
            isOnline: true,
            context: context,
          );
          if (userModel != null) {
            ReusablePopup.show(
                context: context,
                title: "Success",
                message: "Your profile has been saved successfully!",
                type: PopupType.success,
                onConfirm: () {
                  Navigation()
                      .navigateToHome(context: context, userModel: userModel);
                });
          } else {
            print("Failed to add user to Firestore.");
            ReusablePopup.show(
                context: context,
                title: "Failed",
                message: "There was an error when saving your profile...",
                type: PopupType.error);
          }
        } catch (e) {
          print("navigate to home error: $e");
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Image.asset(
                      AssetsManager.tpqmsIcon,
                      height: 210,
                      color: Constants.purple,
                    ),
                  ),
                  //const SizedBox(height: 48),
                  CustomTextField(
                    label: 'Username',
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      if (_usernameError != null) {
                        return _usernameError; // Display error if username is taken
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Phone Number',
                    initialValue: _phoneNumber,
                    enabled: false,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Height (cm)',
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter height';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Age',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter age';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomElevatedButton(
                    text: "Confirm",
                    onPressed: _submitForm,
                    backgroundColor: Constants.purple,
                    foregroundColor: Constants.white,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
