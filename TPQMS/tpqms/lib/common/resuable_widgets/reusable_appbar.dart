import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Title or greeting message
  final String title;
  // Customizable background color
  final Color backgroundColor;
  // Optional TabBar for tabbed navigation
  final TabBar? tabBar;
  // List of action widgets to display in the app bar
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.backgroundColor = Constants.purple, // Default color
    this.tabBar,
    this.actions, // New actions parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30.0),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Title and actions row
            Padding(
              padding: const EdgeInsets.only(
                top: 0,
                bottom: 8.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Takes up remaining space for title
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  // Show actions if provided
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            // Show TabBar if provided
            if (tabBar != null) tabBar!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      tabBar == null ? 100.0 : 160.0); // Adjust height based on TabBar
}
