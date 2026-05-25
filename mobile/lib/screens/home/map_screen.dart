import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';
import '../../providers/geo_provider.dart';
import '../../providers/listings_provider.dart';
import '../../utils/format.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../widgets/primary_button.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  String? _selectedPinId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(geoProvider.notifier).ensureLocation();
      _moveToSearchCenter();
      ref.invalidate(mapPinsProvider);
    });
  }

  void _moveToSearchCenter() {
    final geo = ref.read(geoProvider);
    if (geo.latitude != null && geo.longitude != null) {
      _mapController.move(LatLng(geo.latitude!, geo.longitude!), 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(selectedCategoryProvider);
    final pinsAsync = ref.watch(mapPinsProvider);
    final geo = ref.watch(geoProvider);

    ref.listen(geoProvider, (prev, next) {
      if (prev?.latitude != next.latitude || prev?.longitude != next.longitude) {
        if (next.latitude != null && next.longitude != null) {
          _mapController.move(LatLng(next.latitude!, next.longitude!), _mapController.camera.zoom);
        }
        ref.invalidate(mapPinsProvider);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(geo.latitude ?? 6.5244, geo.longitude ?? 3.3792),
              initialZoom: 13,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  final c = _mapController.camera.center;
                  ref.read(geoProvider.notifier).setSearchCenter(
                        lat: c.latitude,
                        lng: c.longitude,
                        label: ref.read(geoProvider).label ?? 'Map area',
                        source: LocationSource.manual,
                      );
                  ref.invalidate(mapPinsProvider);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zerohunger.app',
              ),
              pinsAsync.maybeWhen(
                data: (pins) => MarkerLayer(
                  markers: pins
                      .map(
                        (pin) => Marker(
                          point: LatLng(pin.latitude, pin.longitude),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPinId = pin.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: kSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedPinId == pin.id ? green500 : kBorder,
                                  width: _selectedPinId == pin.id ? 2 : 1,
                                ),
                                boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
                              ),
                              child: const Icon(Icons.eco, color: green500, size: 22),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                orElse: () => const MarkerLayer(markers: []),
              ),
            ],
          ),
          if (pinsAsync.isLoading)
            const Positioned(top: 120, left: 0, right: 0, child: LinearProgressIndicator(color: green500)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(22),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => showLocationPickerSheet(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: green500, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                geo.label ?? 'Choose area',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: kTextSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                CategoryChipRow(
                  selected: category,
                  onSelected: (c) {
                    ref.read(selectedCategoryProvider.notifier).state = c;
                    ref.invalidate(mapPinsProvider);
                  },
                ),
              ],
            ),
          ),
          if (_selectedPinId != null)
            pinsAsync.maybeWhen(
              data: (pins) {
                final pin = pins.firstWhere((p) => p.id == _selectedPinId);
                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 88,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(pin.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  '${formatDistanceKm(pin.distanceKm)} · ${formatListingDeadline(status: pin.status, deadline: pin.pickupDeadline)}',
                                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100,
                            child: PrimaryButton(
                              label: 'View',
                              onPressed: () => context.push('/receiver/food/${pin.id}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          if (pinsAsync.hasError)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: ErrorState(
                message: '${pinsAsync.error}',
                onRetry: () => ref.invalidate(mapPinsProvider),
              ),
            ),
        ],
      ),
    );
  }
}
