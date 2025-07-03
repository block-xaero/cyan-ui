import 'dart:ui';

import 'package:cyan/theme/cyan_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SideMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? CyanTheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: CyanTheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? CyanTheme.primary : CyanTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? CyanTheme.primary : CyanTheme.text,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
