import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/geo_provider.dart';
import '../providers/listings_provider.dart';

/// Hybrid location: GPS, search by place name, or save current search as profile area.
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

  Future<void> _closeAnd(Future<void> Function() action) async {
    Navigator.pop(context);
    await action();
    ref.invalidate(nearbyListingsProvider);
    ref.invalidate(mapPinsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose area', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.my_location, color: green500),
              title: const Text('Use current location'),
              onTap: () => _closeAnd(() => ref.read(geoProvider.notifier).useCurrentLocation()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search another area',
                hintText: 'e.g. Yaba, Lagos',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                _closeAnd(() => ref.read(geoProvider.notifier).geocodeAndSetCenter(v));
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                final q = _searchController.text.trim();
                if (q.isEmpty) return;
                _closeAnd(() => ref.read(geoProvider.notifier).geocodeAndSetCenter(q));
              },
              child: const Text('Search this area'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(geoProvider.notifier).saveSearchAsProfile();
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    const SnackBar(content: Text('Saved as your pickup area')),
                  );
                }
              },
              child: const Text('Save as my pickup area'),
            ),
          ],
        ),
      ),
    );
  }
}
