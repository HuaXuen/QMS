import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popupmenu.dart';
import 'package:tpqms/common/resuable_widgets/reusable_textfield.dart';
import 'package:tpqms/common/resuable_widgets/reusable_popup.dart';
import 'package:tpqms/src/pages/admin/shared/admin_page_wrapper.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';

class RideManagementPage extends StatefulWidget {
  const RideManagementPage({Key? key}) : super(key: key);

  @override
  State<RideManagementPage> createState() => _RideManagementPageState();
}

class _RideManagementPageState extends State<RideManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _rideNameController = TextEditingController();
  final _heightRequirementController = TextEditingController();
  final _queueTimeController = TextEditingController(text: '--');
  final _maxRidersAllowedController = TextEditingController(text: '2');
  final _latitudeController = TextEditingController(text: '0');
  final _longitudeController = TextEditingController(text: '0');
  final _defaultGeofenceRadiusController = TextEditingController(text: '100');

  String _selectedCategory = 'Water Rides';
  String _selectedStatus = 'Available';
  bool _isCategoryOpen = false;
  bool _isStatusOpen = false;

  final List<String> _categories = [
    'Family Rides',
    'Thrill Rides',
    'Kids Rides',
    'Dark Rides'
  ];

  final List<String> _statuses = [
    'Available',
    'Under Maintenance',
    'Closed',
  ];

  void _resetForm() {
    setState(() {
      _rideNameController.clear();
      _heightRequirementController.clear();
      _queueTimeController.text = '--';
      _maxRidersAllowedController.text = '2';
      _selectedCategory = 'Water Rides';
      _selectedStatus = 'Available';
      _latitudeController.clear();
      _longitudeController.clear();
      _defaultGeofenceRadiusController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final _rideProvider = context.watch<RideProvider>();

    void _submitRide() async {
      if (_formKey.currentState?.validate() == true) {
        try {
          final rideId = await _rideProvider.addRide(
            name: _rideNameController.text,
            category: _selectedCategory,
            status: _selectedStatus,
            heightRequirement: int.parse(_heightRequirementController.text),
            queueTime: 1,
            numOfRidersAllowed: int.parse(_maxRidersAllowedController.text),
            latitude: double.parse(_latitudeController.text),
            longitude: double.parse(_longitudeController.text),
            radiusInMeters: double.parse(_defaultGeofenceRadiusController.text),
          );

          if (rideId != null) {
            ReusablePopup.show(
              context: context,
              title: "Success",
              message: "Ride added successfully!",
              type: PopupType.success,
              onConfirm: () {
                _resetForm();
              },
            );
          } else {
            ReusablePopup.show(
              context: context,
              title: "Error",
              message: "Failed to add ride. Unknown error occurred.",
              type: PopupType.error,
            );
          }
        } catch (e) {
          ReusablePopup.show(
            context: context,
            title: "Error",
            message: e.toString(),
            type: PopupType.error,
          );
        }
      }
    }

    return AdminPageWrapper(
        currentIndex: 1, // This indicates we're on the Add Rides page
        child: Scaffold(
          backgroundColor: Constants.primaryBackground,
          appBar: AppBar(
            title: const Text(
              'Add New Ride',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Name',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: '',
                            controller: _rideNameController,
                            showLabel: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a ride name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomPopupMenu(
                            label: 'Category',
                            value: _selectedCategory,
                            items: _categories,
                            isOpen: _isCategoryOpen,
                            onSelected: (String value) {
                              setState(() {
                                _selectedCategory = value;
                                _isCategoryOpen = false;
                              });
                            },
                            onOpened: () {
                              setState(() {
                                _isCategoryOpen = true;
                              });
                            },
                            onCanceled: () {
                              setState(() {
                                _isCategoryOpen = false;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          CustomPopupMenu(
                            label: 'Status',
                            value: _selectedStatus,
                            items: _statuses,
                            isOpen: _isStatusOpen,
                            onSelected: (String value) {
                              setState(() {
                                _selectedStatus = value;
                                _isStatusOpen = false;
                              });
                            },
                            onOpened: () {
                              setState(() {
                                _isStatusOpen = true;
                              });
                            },
                            onCanceled: () {
                              setState(() {
                                _isStatusOpen = false;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Height Requirement',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: '',
                            controller: _heightRequirementController,
                            showLabel: false,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffix: const Text(
                              'cm',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Average Queue Time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          CustomTextField(
                            label: '',
                            controller: _queueTimeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Max Riders Allowed',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            label: '',
                            controller: _maxRidersAllowedController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Latitude Coordinates',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          CustomTextField(
                            label: '',
                            controller: _latitudeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Longitude Coordinates',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          CustomTextField(
                            label: '',
                            controller: _longitudeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Geofence Radius',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          CustomTextField(
                            label: '',
                            controller: _defaultGeofenceRadiusController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffix: const Text(
                              'meters',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).padding.bottom +
                                    120, // Add extra padding for the navigation bar
                              ),
                              child: ElevatedButton(
                                onPressed: _submitRide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _rideNameController.dispose();
    _heightRequirementController.dispose();
    _queueTimeController.dispose();
    _maxRidersAllowedController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _defaultGeofenceRadiusController.dispose();
    super.dispose();
  }
}
