import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/src/common/constants.dart';
import 'package:tpqms/src/common/reusable_widget.dart';
import 'package:tpqms/src/providers/userinfo_provider.dart';
import 'package:tpqms/src/utilities/assets_manager.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final uid = args[Constants.uid] as String;
    final phoneNumber = args[Constants.phoneNumber] as String;
    //final _userInfoProvider = context.watch<UserInfoProvider>();

    void _submitForm() async {
      if (_formKey.currentState!.validate()) {
        final userInfoProvider =
            Provider.of<UserInfoProvider>(context, listen: false);
        print("uid: ${uid}");
        print("phone: ${phoneNumber}");

        await userInfoProvider.addUserToFirestore(
          uid: uid, // from arguments
          name: _usernameController.text,
          phoneNumber: phoneNumber, // from arguments
          age: _ageController.text,
          height: _heightController.text,
          context: context,
        );
      }
    }

    // TODO:
    // retrieve UID from authentication firebase and set it as id for firestore

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
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: 'Phone Number',
                    initialValue: phoneNumber,
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
                  CustomElevatedButton(text: "Confirm", onPressed: _submitForm)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
