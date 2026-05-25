import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/enums.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key, required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I want to',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                icon: Icons.storefront_outlined,
                label: 'Share food',
                selected: selected == UserRole.donor,
                onTap: () => onChanged(UserRole.donor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoleChip(
                icon: Icons.place_outlined,
                label: 'Find food',
                selected: selected == UserRole.receiver,
                onTap: () => onChanged(UserRole.receiver),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? green100 : gray100.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? green500 : kBorder, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? green500 : kTextSecondary, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? green500 : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
