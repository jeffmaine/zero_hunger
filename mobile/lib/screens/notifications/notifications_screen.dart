import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/app_notification.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_dashboard_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/format.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              invalidateNotifications(ref);
              ref.invalidate(donorDashboardProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: green500)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: kErrorText)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(notificationsListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (result) {
          if (result.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 56, color: kTextDisabled),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kTextPrimary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Claims and updates will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: green500,
            onRefresh: () async {
              invalidateNotifications(ref);
              ref.invalidate(donorDashboardProvider);
              await ref.read(notificationsListProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: result.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = result.items[i];
                return _NotificationTile(
                  notification: n,
                  onTap: () => _onTap(context, ref, n),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, AppNotificationModel n) async {
    if (!n.isRead) {
      await ref.read(notificationServiceProvider).markRead(n.id);
      invalidateNotifications(ref);
      ref.invalidate(donorDashboardProvider);
    }
    if (!context.mounted) return;

    final role = ref.read(authProvider).user?.role;
    switch (n.type) {
      case AppNotificationType.claimReceived:
        if (n.listingId != null) context.push('/donor/listing/${n.listingId}');
        break;
      case AppNotificationType.claimApproved:
      case AppNotificationType.claimRejected:
        if (role == UserRole.donor) {
          context.go('/donor/listings');
        } else {
          context.go('/receiver/claims');
        }
        break;
      case AppNotificationType.listingExpiring:
        if (n.listingId != null) {
          if (role == UserRole.donor) {
            context.push('/donor/listing/${n.listingId}');
          } else {
            context.push('/receiver/food/${n.listingId}');
          }
        }
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final (icon, bg, fg) = _style(notification.type);

    return Material(
      color: unread ? green50 : kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: unread ? green100 : kBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: green500, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(fontSize: 12, color: kTextSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatRelativeTimeAgo(notification.createdAt),
                        style: const TextStyle(fontSize: 10, color: kTextDisabled),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: kTextDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _style(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.claimReceived => (
          Icons.person_add_alt_1_rounded,
          green100,
          green500,
        ),
      AppNotificationType.claimApproved => (
          Icons.check_circle_outline_rounded,
          green100,
          green500,
        ),
      AppNotificationType.claimRejected => (
          Icons.cancel_outlined,
          kErrorBg,
          kErrorText,
        ),
      AppNotificationType.listingExpiring => (
          Icons.schedule_rounded,
          const Color(0xFFFFF3E0),
          kAccent,
        ),
    };
  }
}
