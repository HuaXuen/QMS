import 'package:flutter/material.dart';
import 'package:tpqms/common/constants.dart';

class NavBarItem {
  final IconData icon;
  final String label;
  final Function()? onTap;

  NavBarItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

class CustomNavigationBar extends StatefulWidget {
  final List<NavBarItem> items;
  final int initialIndex;
  final Function(int)? onIndexChanged;
  final Color? activeColor;
  final Color inactiveColor;
  final double? height;
  final double itemSpacing;

  const CustomNavigationBar({
    Key? key,
    required this.items,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.activeColor,
    this.inactiveColor = Colors.grey,
    this.height = 64,
    this.itemSpacing = 0,
  }) : super(key: key);

  @override
  State<CustomNavigationBar> createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.items.length,
            (index) => _buildNavItem(index),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = widget.items[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        widget.onIndexChanged?.call(index);
        item.onTap?.call();
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
              item.icon,
              color: isSelected
                  ? (widget.activeColor ?? Constants.purple)
                  : widget.inactiveColor,
              size: 24,
            ),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? (widget.activeColor ?? Constants.purple)
                    : widget.inactiveColor,
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
