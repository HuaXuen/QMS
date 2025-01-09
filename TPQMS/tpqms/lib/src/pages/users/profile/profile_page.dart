// profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/main_page_wrapper.dart';
import 'package:tpqms/common/resuable_widgets/reusable_appbar.dart';
import 'package:tpqms/common/resuable_widgets/reusable_textfield.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popup.dart';
import 'package:tpqms/src/providers/auth_providers/userinfo_provider.dart';
import 'package:tpqms/src/providers/auth_providers/authentication_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Add ScrollController for keyboard handling
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserInfoProvider>();

    // Initialize controllers with current user data
    _nameController = TextEditingController(text: userProvider.name);
    _ageController = TextEditingController(text: userProvider.age);
    _heightController = TextEditingController(text: userProvider.height);

    // Add listener to scroll when keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.addListener(() {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Add update user function similar to userinformation_page
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userProvider = context.read<UserInfoProvider>();

      // First validate username
      bool isTaken = await userProvider.validateUsername(_nameController.text);
      if (isTaken && _nameController.text != userProvider.name) {
        ReusablePopup.show(
          context: context,
          title: 'Error',
          message: 'This username is already taken',
          type: PopupType.error,
        );
        return;
      }

      // Update user info
      await userProvider.updateUserInfo(
        name: _nameController.text,
        age: _ageController.text,
        height: _heightController.text,
        context: context,
      );

      if (mounted) {
        ReusablePopup.show(
          context: context,
          title: 'Success',
          message: 'Profile updated successfully!',
          type: PopupType.success,
          onConfirm: () {
            setState(() => _isEditing = false);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ReusablePopup.show(
          context: context,
          title: 'Error',
          message: 'Failed to update profile: $e',
          type: PopupType.error,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthenticationProvider>().logout(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserInfoProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return MainPageWrapper(
      currentIndex: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: CustomAppBar(
          title: 'My Profile',
          backgroundColor: Constants.purple,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              color: Constants.white,
            ),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 80),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Constants.purple,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row with title and edit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isEditing ? Icons.save : Icons.edit,
                                color: Constants.purple,
                              ),
                              onPressed: () {
                                if (_isEditing) {
                                  _saveChanges();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Phone Number field (non-editable)
                        CustomTextField(
                          label: 'Phone Number',
                          initialValue: userProvider.phoneNumber,
                          enabled: false,
                          textStyle: const TextStyle(color: Colors.black54),
                          fillColor: Colors.grey.shade200,
                          labelColor: Colors.black87,
                        ),
                        const SizedBox(height: 16),

                        // Name field
                        CustomTextField(
                          label: 'Name',
                          controller: _nameController,
                          enabled: _isEditing,
                          textStyle: const TextStyle(color: Colors.black),
                          fillColor: Colors.grey.shade300,
                          labelColor: Colors.black87,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Age field
                        CustomTextField(
                          label: 'Age',
                          controller: _ageController,
                          enabled: _isEditing,
                          textStyle: const TextStyle(color: Colors.black),
                          fillColor: Colors.grey.shade300,
                          labelColor: Colors.black87,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your age';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Height field
                        CustomTextField(
                          label: 'Height (cm)',
                          controller: _heightController,
                          enabled: _isEditing,
                          textStyle: const TextStyle(color: Colors.black),
                          fillColor: Colors.grey.shade300,
                          labelColor: Colors.black87,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your height';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // SizedBox(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: _handleLogout,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.red,
                //       padding: const EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //     ),
                //     child: const Text(
                //       'Logout',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
