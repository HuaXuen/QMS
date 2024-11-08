import 'package:flutter/material.dart';

class CustomPopupMenu extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onSelected;
  final bool isOpen;
  final Function() onOpened;
  final Function() onCanceled;
  final String? label;

  const CustomPopupMenu({
    Key? key,
    required this.value,
    required this.items,
    required this.onSelected,
    required this.isOpen,
    required this.onOpened,
    required this.onCanceled,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity, // Add this to match parent width
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
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOpen
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF334155),
                  width: isOpen ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            position: PopupMenuPosition.under,
            color: const Color(0xFF1E293B),
            constraints: const BoxConstraints(
              minWidth: double.infinity, // Modified this
              maxWidth: double.infinity, // Added this
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
