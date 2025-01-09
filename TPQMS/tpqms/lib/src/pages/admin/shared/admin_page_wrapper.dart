import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/src/pages/admin/ride_management/admin_home_page.dart';
import 'package:tpqms/src/pages/admin/ride_analytics/ride_analytics_page.dart';
import 'package:tpqms/src/pages/admin/ride_management/add_ride_page.dart';

class AdminPageWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AdminPageWrapper({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The main content
          child,

          // Admin Navigation Bar
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AdminNavigationBar(
              currentIndex: currentIndex,
              onItemSelected: (index) {
                // Handle navigation based on index
                switch (index) {
                  case 0:
                    // Navigate to Admin Home
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomePage(),
                      ),
                    );
                    break;
                  case 1:
                    // Navigate to Ride Management
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideManagementPage(),
                      ),
                    );
                    break;
                  case 2:
                    // Navigate to Ride Management
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RideAnalyticsPage(),
                      ),
                    );
                    break;
                  // Add more cases for other pages
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onItemSelected;

  const AdminNavigationBar({
    Key? key,
    required this.currentIndex,
    this.onItemSelected,
  }) : super(key: key);

  @override
  State<AdminNavigationBar> createState() => _AdminNavigationBarState();
}

class _AdminNavigationBarState extends State<AdminNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(AdminNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Constants.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            label: 'Home',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.add_circle_outline,
            label: 'Add Rides',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.analytics_outlined,
            label: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        widget.onItemSelected?.call(index);
      },
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Constants.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Constants.purple.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2.5,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? Constants.purple : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Constants.purple
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
