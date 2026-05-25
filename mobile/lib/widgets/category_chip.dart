import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final opt = categoryOptions[i];
          final active = selected == opt.apiValue;
          return GestureDetector(
            onTap: () => onSelected(opt.apiValue),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? green100 : kSurface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: active ? green500 : kBorder),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: active ? green500 : kTextSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RadiusChipRow extends StatelessWidget {
  const RadiusChipRow({
    super.key,
    required this.selectedKm,
    required this.onSelected,
  });

  final double selectedKm;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: radiusOptionsKm.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final km = radiusOptionsKm[i];
          final active = selectedKm == km;
          return GestureDetector(
            onTap: () => onSelected(km),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? green100 : kSurface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: active ? green500 : kBorder),
              ),
              child: Text(
                '${km.toInt()} km',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? green500 : kTextSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
