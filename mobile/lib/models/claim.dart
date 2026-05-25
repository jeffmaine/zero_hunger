import '../core/json_parse.dart';
import 'enums.dart';
import 'listing.dart';

class ClaimModel {
  ClaimModel({
    required this.id,
    required this.listingId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.listing,
    this.receiverName,
    this.pickupCode,
    this.collectedAt,
    this.priorityRank,
    this.receiverPickups,
    this.receiverNoShows,
  });

  final String id;
  final String listingId;
  final String receiverId;
  final ClaimStatus status;
  final DateTime createdAt;
  final ListingModel? listing;
  final String? receiverName;
  final String? pickupCode;
  final DateTime? collectedAt;
  final int? priorityRank;
  final int? receiverPickups;
  final int? receiverNoShows;

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: parseUuid(json['id']),
      listingId: parseUuid(json['listing_id']),
      receiverId: parseUuid(json['receiver_id']),
      status: claimStatusFromString(json['status'] as String?) ?? ClaimStatus.pending,
      createdAt: parseDateTime(json['created_at']),
      listing: json['listing'] != null
          ? ListingModel.fromJson(json['listing'] as Map<String, dynamic>)
          : null,
      receiverName: json['receiver_name'] as String?,
      pickupCode: json['pickup_code'] as String?,
      collectedAt: json['collected_at'] != null ? parseDateTime(json['collected_at']) : null,
      priorityRank: json['priority_rank'] as int?,
      receiverPickups: json['receiver_pickups'] as int?,
      receiverNoShows: json['receiver_no_shows'] as int?,
    );
  }
}

class ClaimLimitsModel {
  ClaimLimitsModel({
    required this.maxActiveClaims,
    required this.activeClaims,
    required this.cooldownHours,
    required this.canClaim,
    this.cooldownEndsAt,
    this.message,
    this.claimNoShows = 0,
    this.maxNoShows = 3,
  });

  final int maxActiveClaims;
  final int activeClaims;
  final int cooldownHours;
  final bool canClaim;
  final DateTime? cooldownEndsAt;
  final String? message;
  final int claimNoShows;
  final int maxNoShows;

  bool get isNoShowBlocked => claimNoShows >= maxNoShows;

  factory ClaimLimitsModel.fromJson(Map<String, dynamic> json) {
    return ClaimLimitsModel(
      maxActiveClaims: parseInt(json['max_active_claims'], fallback: 2),
      activeClaims: parseInt(json['active_claims']),
      cooldownHours: parseInt(json['cooldown_hours'], fallback: 6),
      canClaim: json['can_claim'] as bool? ?? true,
      cooldownEndsAt: json['cooldown_ends_at'] != null
          ? parseDateTime(json['cooldown_ends_at'])
          : null,
      message: json['message'] as String?,
      claimNoShows: parseInt(json['claim_no_shows']),
      maxNoShows: parseInt(json['max_no_shows'], fallback: 3),
    );
  }
}
