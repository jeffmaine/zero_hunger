import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificationServiceProvider).fetchUnreadCount();
});

final notificationsListProvider =
    FutureProvider.autoDispose<NotificationListResult>((ref) async {
  return ref.watch(notificationServiceProvider).fetchList();
});

void invalidateNotifications(WidgetRef ref) {
  ref.invalidate(unreadNotificationsProvider);
  ref.invalidate(notificationsListProvider);
}
