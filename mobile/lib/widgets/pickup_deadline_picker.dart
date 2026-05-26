import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../utils/format.dart';
import '../utils/pickup_deadline_utils.dart';

/// Pickup window end time for donor create/edit listing.
class PickupDeadlinePicker extends StatelessWidget {
  const PickupDeadlinePicker({
    super.key,
    required this.deadline,
    required this.onChanged,
  });

  final DateTime deadline;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      helpText: 'Last day to pick up',
      cancelText: 'Cancel',
      confirmText: 'Next',
      firstDate: now,
      lastDate: now.add(kMaxPickupHorizon),
      initialDate: deadline.isBefore(now) ? now.add(const Duration(hours: 2)) : deadline,
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      helpText: 'Pickup ends at',
      cancelText: 'Cancel',
      confirmText: 'Set',
      initialTime: TimeOfDay.fromDateTime(deadline),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (time == null || !context.mounted) return;

    var picked = roundDeadlineToQuarterHour(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
    final error = validatePickupDeadline(picked);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      if (picked.isBefore(now.add(kMinPickupLeadTime))) {
        picked = deadlineFromNow(const Duration(hours: 2));
      }
    }
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final validation = validatePickupDeadline(deadline);
    final urgent = isUrgentDeadline(deadline);
    final critical = isCriticalDeadline(deadline);
    final accentColor = critical
        ? kErrorText
        : urgent
            ? kAccent
            : green500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: validation != null ? const Color(0xFFFECACA) : kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: green100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup window ends',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPickupDeadlineChoice(deadline),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      validation ?? formatPickupDeadlineHint(deadline),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: validation != null ? kErrorText : kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'QUICK SET',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: kTextDisabled),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pickupDeadlinePresets.map((preset) {
              final selected = deadlinesMatchPreset(deadline, preset);
              return FilterChip(
                label: Text(preset.label),
                selected: selected,
                onSelected: (_) => onChanged(preset.resolve()),
                selectedColor: green100,
                checkmarkColor: green500,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? green500 : kTextSecondary,
                ),
                side: BorderSide(color: selected ? green500 : kBorder),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickCustom(context),
            icon: const Icon(Icons.edit_calendar_outlined, size: 18),
            label: const Text('Choose date & time'),
            style: OutlinedButton.styleFrom(
              foregroundColor: green500,
              side: const BorderSide(color: green500),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
