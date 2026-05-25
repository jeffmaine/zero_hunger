import '../core/json_parse.dart';
import 'listing.dart';

class DonorStatsModel {
  DonorStatsModel({
    required this.activeListings,
    required this.totalPosted,
    required this.pendingClaims,
    required this.unreadNotifications,
  });

  final int activeListings;
  final int totalPosted;
  final int pendingClaims;
  final int unreadNotifications;

  factory DonorStatsModel.fromJson(Map<String, dynamic> json) {
    return DonorStatsModel(
      activeListings: parseInt(json['active_listings']),
      totalPosted: parseInt(json['total_posted']),
      pendingClaims: parseInt(json['pending_claims']),
      unreadNotifications: parseInt(json['unread_notifications']),
    );
  }
}

class NearbyActivityModel {
  NearbyActivityModel({
    required this.listingId,
    required this.donorId,
    required this.donorName,
    required this.listingTitle,
    required this.createdAt,
    this.imageUrl,
    this.distanceKm,
  });

  final String listingId;
  final String donorId;
  final String donorName;
  final String listingTitle;
  final String? imageUrl;
  final DateTime createdAt;
  final double? distanceKm;

  factory NearbyActivityModel.fromJson(Map<String, dynamic> json) {
    return NearbyActivityModel(
      listingId: parseUuid(json['listing_id']),
      donorId: parseUuid(json['donor_id']),
      donorName: json['donor_name'] as String? ?? 'Someone',
      listingTitle: json['listing_title'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      createdAt: parseDateTime(json['created_at']),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

class DonorDashboardModel {
  DonorDashboardModel({
    required this.stats,
    required this.recentListings,
    required this.nearbyActivity,
  });

  final DonorStatsModel stats;
  final List<ListingModel> recentListings;
  final List<NearbyActivityModel> nearbyActivity;

  factory DonorDashboardModel.fromJson(Map<String, dynamic> json) {
    return DonorDashboardModel(
      stats: DonorStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      recentListings: (json['recent_listings'] as List<dynamic>)
          .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyActivity: (json['nearby_activity'] as List<dynamic>)
          .map((e) => NearbyActivityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
