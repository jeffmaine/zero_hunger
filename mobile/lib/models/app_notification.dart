import '../core/json_parse.dart';

enum AppNotificationType {
  claimReceived,
  claimApproved,
  claimRejected,
  listingExpiring,
}

class AppNotificationModel {
  AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.listingId,
    this.claimId,
    this.readAt,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? listingId;
  final String? claimId;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: parseUuid(json['id']),
      type: _typeFromApi(json['type'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      listingId: parseUuidOrNull(json['listing_id']),
      claimId: parseUuidOrNull(json['claim_id']),
      readAt: json['read_at'] != null ? parseDateTime(json['read_at']) : null,
      createdAt: parseDateTime(json['created_at']),
    );
  }

  static AppNotificationType _typeFromApi(String value) {
    return switch (value) {
      'claim_received' => AppNotificationType.claimReceived,
      'claim_approved' => AppNotificationType.claimApproved,
      'claim_rejected' => AppNotificationType.claimRejected,
      'listing_expiring' => AppNotificationType.listingExpiring,
      _ => AppNotificationType.claimReceived,
    };
  }
}

class NotificationListResult {
  NotificationListResult({required this.unreadCount, required this.items});

  final int unreadCount;
  final List<AppNotificationModel> items;

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] as List<dynamic>;
    return NotificationListResult(
      unreadCount: parseInt(json['unread_count']),
      items: list
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
