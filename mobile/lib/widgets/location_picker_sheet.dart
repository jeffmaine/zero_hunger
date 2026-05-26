import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/geo_provider.dart';
import '../providers/listings_provider.dart';
import '../utils/pickup_area_copy.dart';

/// Pick where the user will collect food (GPS, place search, or map on Map tab).
Future<void> showLocationPickerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _LocationPickerSheet(
      parentContext: context,
    ),
  );
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  ConsumerState<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  late final TextEditingController _searchController;

  static const _examplePlaces = [
    'Yaba, Lagos',
    'Ikeja City Mall',
    'Lekki Phase 1',
    'Computer Village',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(geoProvider).label ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _applyAndClose(Future<void> Function() action) async {
    Navigator.pop(context);
    await action();
    ref.invalidate(nearbyListingsProvider);
    ref.invalidate(mapPinsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final geo = ref.watch(geoProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: gray300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Where will you pick up food?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'We show listings near your pickup area — not only where your phone is right now. '
              'Heading to a junction or bus stop soon? Search that place instead.',
              style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4),
            ),
            if (geo.hasCoords) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: green50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: green100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: green500, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            geo.displayTitle,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            geo.displaySubtitle,
                            style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('OPTION 1 — RIGHT NOW', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.my_location, color: green500),
              ),
              title: const Text('Use my current location'),
              subtitle: const Text(
                'Best when you’re already at the pickup spot',
                style: TextStyle(fontSize: 12),
              ),
              onTap: geo.isLoading
                  ? null
                  : () => _applyAndClose(
                        () => ref.read(geoProvider.notifier).useCurrentLocation(syncProfile: true),
                      ),
            ),
            const SizedBox(height: 16),
            Text('OPTION 2 — WHERE YOU’LL BE', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search area or landmark',
                hintText: 'e.g. Yaba junction, CMS bus stop',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                _applyAndClose(() => ref.read(geoProvider.notifier).geocodeAndSetCenter(v));
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examplePlaces.map((place) {
                return ActionChip(
                  label: Text(place, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    _searchController.text = place;
                    _applyAndClose(() => ref.read(geoProvider.notifier).geocodeAndSetCenter(place));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: geo.isLoading
                  ? null
                  : () {
                      final q = _searchController.text.trim();
                      if (q.isEmpty) return;
                      _applyAndClose(() => ref.read(geoProvider.notifier).geocodeAndSetCenter(q));
                    },
              style: FilledButton.styleFrom(backgroundColor: green500),
              child: const Text('Use this area'),
            ),
            if (geo.error != null) ...[
              const SizedBox(height: 8),
              Text(geo.error!, style: const TextStyle(color: kErrorText, fontSize: 12)),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Tip: On the Map tab you can drag the map — we search around the center.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kTextSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(geoProvider.notifier).saveSearchAsProfile();
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Pickup area saved to your profile'),
                    ),
                  );
                }
              },
              child: const Text('Save this area to my profile'),
            ),
          ],
        ),
      ),
    );
  }
}
