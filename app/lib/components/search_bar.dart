import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final EdgeInsets? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final TextInputAction? textInputAction;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.hintText = 'Buscar...',
    this.prefixIcon = Icons.search,
    this.suffixIcon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.elevation = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundColor,
    this.textInputAction = TextInputAction.search,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding!,
      child: Material(
        elevation: elevation!,
        borderRadius: borderRadius!,
        color: backgroundColor ?? colorScheme.surface,
        child: TextField(
          controller: controller,
          enabled: enabled,
          onTap: onTap,
          onChanged: onChanged,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: .6),
            ),
            prefixIcon: prefixIcon != null 
              ? Icon(
                  prefixIcon,
                  color: colorScheme.onSurface.withValues(alpha: .7),
                )
              : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: borderRadius!,
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: backgroundColor ?? colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }
}