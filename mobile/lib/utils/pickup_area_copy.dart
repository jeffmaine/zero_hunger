import '../providers/geo_provider.dart';

extension PickupAreaCopy on GeoState {
  /// Short title for chips and headers.
  String get displayTitle {
    if (label != null && label!.isNotEmpty) return label!;
    if (hasCoords) return 'Near you';
    return 'Set pickup area';
  }

  /// Explains GPS vs a place the user chose.
  String get displaySubtitle {
    if (!hasCoords) {
      return 'Choose where you can collect food — not only where your phone is right now.';
    }
    switch (source) {
      case LocationSource.gps:
        return 'Using your phone’s location right now. Tap to pick a junction or area you’ll be at instead.';
      case LocationSource.manual:
        return 'Showing food near this spot. Good if you’re heading here soon.';
      case LocationSource.hybrid:
        return 'Saved on your profile. Tap to update where you’ll pick up food.';
    }
  }

  String get sourceBadge {
    switch (source) {
      case LocationSource.gps:
        return 'Live GPS';
      case LocationSource.manual:
        return 'Chosen area';
      case LocationSource.hybrid:
        return 'Saved area';
    }
  }
}
