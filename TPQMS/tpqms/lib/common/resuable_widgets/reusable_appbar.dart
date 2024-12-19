import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // Title or greeting message
  final Color backgroundColor; // Customizable background color
  final TabBar? tabBar; // Optional TabBar

  const CustomAppBar({
    Key? key,
    required this.title,
    this.backgroundColor = Constants.purple, // Default color
    this.tabBar,
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
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 8.0),
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
            if (tabBar != null) tabBar!, // Show TabBar if provided
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      tabBar == null ? 100.0 : 160.0); // Adjust height based on TabBar
}
