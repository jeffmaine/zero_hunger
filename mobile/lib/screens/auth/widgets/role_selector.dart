import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/enums.dart';

/// Donor / receiver / volunteer — used on register and login before Google or email signup.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

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
            const SizedBox(width: 8),
            Expanded(
              child: _RoleChip(
                icon: Icons.place_outlined,
                label: 'Find food',
                selected: selected == UserRole.receiver,
                onTap: () => onChanged(UserRole.receiver),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RoleChip(
                icon: Icons.pedal_bike_outlined,
                label: 'Deliver',
                selected: selected == UserRole.volunteer,
                onTap: () => onChanged(UserRole.volunteer),
              ),
            ),
          ],
        ),
        if (selected == UserRole.volunteer) ...[
          const SizedBox(height: 8),
          Text(
            'Delivery helper sign-up opens in Phase 2. Choose Share or Find food to join now.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kTextSecondary,
                  height: 1.35,
                ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? green500 : kBorder, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? green500 : kTextSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
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
