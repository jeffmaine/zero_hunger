import '../core/json_parse.dart';
import 'enums.dart';

class ListingModel {
  ListingModel({
    required this.id,
    required this.donorId,
    required this.title,
    this.description,
    required this.quantity,
    required this.category,
    this.imageUrl,
    required this.pickupDeadline,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.distanceKm,
    this.donorName,
    this.donorVerified,
    this.listedToday,
    this.pickupLocationLabel,
  });

  final String id;
  final String donorId;
  final String title;
  final String? description;
  final String quantity;
  final String category;
  final String? imageUrl;
  final DateTime pickupDeadline;
  final double latitude;
  final double longitude;
  final ListingStatus status;
  final DateTime createdAt;
  final double? distanceKm;
  final String? donorName;
  final bool? donorVerified;
  final bool? listedToday;
  final String? pickupLocationLabel;

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: parseUuid(json['id']),
      donorId: parseUuid(json['donor_id']),
      title: json['title'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      pickupDeadline: DateTime.parse(json['pickup_deadline'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: listingStatusFromString(json['status'] as String?) ?? ListingStatus.available,
      createdAt: DateTime.parse(json['created_at'] as String),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      donorName: json['donor_name'] as String?,
      donorVerified: json['donor_verified'] as bool?,
      listedToday: json['listed_today'] as bool?,
      pickupLocationLabel: json['pickup_location_label'] as String?,
    );
  }
}

class MapPinModel {
  MapPinModel({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.pickupDeadline,
    required this.status,
  });

  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final DateTime pickupDeadline;
  final ListingStatus status;

  factory MapPinModel.fromJson(Map<String, dynamic> json) {
    return MapPinModel(
      id: parseUuid(json['id']),
      title: json['title'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      pickupDeadline: DateTime.parse(json['pickup_deadline'] as String),
      status: listingStatusFromString(json['status'] as String?) ?? ListingStatus.available,
    );
  }
}
