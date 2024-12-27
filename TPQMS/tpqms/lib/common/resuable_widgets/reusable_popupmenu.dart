import 'package:flutter/material.dart';

class CustomPopupMenu extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onSelected;
  final bool isOpen;
  final Function() onOpened;
  final Function() onCanceled;
  final String? label;

  // Color customization parameters with defaults matching the original implementation
  final Color labelTextColor;
  final Color itemTextColor;
  final Color containerBackgroundColor;
  final Color containerBorderColorDefault;
  final Color containerBorderColorOpen;
  final double containerBorderWidthDefault;
  final double containerBorderWidthOpen;
  final Color selectedValueTextColor;
  final Color dropdownArrowColor;
  final Color menuBackgroundColor;

  const CustomPopupMenu({
    Key? key,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.isOpen,
    required this.onOpened,
    required this.onCanceled,
    this.label,
    // Default colors matching the original implementation
    this.labelTextColor = Colors.white70,
    this.itemTextColor = Colors.white,
    this.containerBackgroundColor = const Color(0xFF1E293B),
    this.containerBorderColorDefault = const Color(0xFF334155),
    this.containerBorderColorOpen = const Color(0xFF8B5CF6),
    this.containerBorderWidthDefault = 1,
    this.containerBorderWidthOpen = 2,
    this.selectedValueTextColor = Colors.white,
    this.dropdownArrowColor = Colors.white,
    this.menuBackgroundColor = const Color(0xFF1E293B),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: labelTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          child: PopupMenuButton<String>(
            initialValue: value,
            onSelected: onSelected,
            onOpened: onOpened,
            onCanceled: onCanceled,
            itemBuilder: (BuildContext context) {
              return items.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      item,
                      style: TextStyle(color: itemTextColor),
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: containerBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOpen
                      ? containerBorderColorOpen
                      : containerBorderColorDefault,
                  width: isOpen
                      ? containerBorderWidthOpen
                      : containerBorderWidthDefault,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: TextStyle(color: selectedValueTextColor),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: dropdownArrowColor,
                  ),
                ],
              ),
            ),
            position: PopupMenuPosition.under,
            color: menuBackgroundColor,
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              maxWidth: double.infinity,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
