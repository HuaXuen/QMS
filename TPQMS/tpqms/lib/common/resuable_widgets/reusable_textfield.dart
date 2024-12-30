import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final bool showLabel;
  final TextStyle? textStyle;
  final Color? fillColor;
  final Color? labelColor;
  final EdgeInsetsGeometry? contentPadding;
  final Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.label,
    this.controller,
    this.initialValue,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.hintText,
    this.prefix,
    this.suffix,
    this.showLabel = true,
    this.textStyle = const TextStyle(color: Colors.white), // Default white text
    this.fillColor = const Color(0xFF1E293B), // Default dark background
    this.labelColor = Colors.white, // Default label color
    this.contentPadding,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? Colors.white70, // Use labelColor parameter
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: onChanged,
          style: textStyle, // Use textStyle parameter
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor, // Use fillColor parameter
            hintText: hintText,
            hintStyle: textStyle?.copyWith(color: Colors.white54) ??
                const TextStyle(
                    color: Colors.white54), // Derive hint style from textStyle
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF334155), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefix: prefix,
            suffix: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
