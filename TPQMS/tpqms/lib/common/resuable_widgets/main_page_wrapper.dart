import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tpqms/common/constants.dart';
import 'package:tpqms/common/resuable_widgets/reusable_navbar.dart';
import 'package:tpqms/src/providers/common_providers/navigation.dart';
import 'package:tpqms/src/providers/user_providers/ride_provider.dart';

class MainPageWrapper extends StatelessWidget {
  // This widget wraps each main page and adds the navbar
  final Widget child;
  final int currentIndex; // Which navbar item should be highlighted

  const MainPageWrapper({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Navigation navigation = Navigation();
    final rideProvider = Provider.of<RideProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          // The main page content
          child,
          // The navigation bar
          CustomNavigationBar(
            initialIndex: currentIndex,
            items: [
              NavBarItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () {
                  // Only navigate if we're not already on home
                  if (currentIndex != 0) {
                    navigation.navigateToHome(context: context);
                  }
                },
              ),
              NavBarItem(
                icon: Icons.timer_outlined,
                label: 'Queue',
                onTap: () {
                  if (currentIndex != 1) {
                    navigation.navigateToQueue(context: context);
                  }
                },
              ),
              NavBarItem(
                icon: Icons.qr_code_scanner,
                label: 'Ticket',
                onTap: () {
                  if (currentIndex != 2) {
                    navigation.navigateToTicket(context: context);
                  }
                },
              ),
              NavBarItem(
                icon: Icons.map_outlined,
                label: 'Map',
                onTap: () {
                  print("havent bro");
                },
              ),
              NavBarItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  if (currentIndex != 4) {
                    navigation.navigateToProfile(context: context);
                  }
                },
              ),
              // Add other items for Map and Profile when ready
            ],
          ),
        ],
      ),
    );
  }
}
