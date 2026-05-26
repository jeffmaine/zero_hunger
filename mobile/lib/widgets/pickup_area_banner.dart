import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/geo_provider.dart';
import '../utils/pickup_area_copy.dart';
import 'location_picker_sheet.dart';

/// Explains pickup area vs GPS and opens the location picker.
class PickupAreaBanner extends ConsumerWidget {
  const PickupAreaBanner({
    super.key,
    this.compact = false,
    this.onAreaChanged,
  });

  final bool compact;
  final VoidCallback? onAreaChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geo = ref.watch(geoProvider);

    return Material(
      color: compact ? green50 : kSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await showLocationPickerSheet(context, ref);
          onAreaChanged?.call();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: compact ? green100 : kBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                geo.hasCoords ? Icons.place_outlined : Icons.location_searching,
                color: green500,
                size: compact ? 20 : 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Your pickup area',
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary,
                          ),
                        ),
                        if (geo.hasCoords) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: green100,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              geo.sourceBadge,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: green500),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      geo.displayTitle,
                      style: TextStyle(
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: compact ? green500 : kTextPrimary,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 4),
                      Text(
                        geo.displaySubtitle,
                        style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      compact ? 'Tap to change area' : 'Tap to change — e.g. a junction you’ll reach in 10 minutes',
                      style: TextStyle(
                        fontSize: 11,
                        color: compact ? green500 : kTextDisabled,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: compact ? green500 : kTextDisabled, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
