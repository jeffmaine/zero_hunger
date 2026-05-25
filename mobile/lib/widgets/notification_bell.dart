import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/donor_dashboard_provider.dart';
import '../providers/notifications_provider.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
    this.iconSize = 26,
    this.badgeCount,
  });

  final double iconSize;

  /// When set (e.g. from dashboard), avoids a separate unread-count request.
  final int? badgeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(unreadNotificationsProvider);
    final count = badgeCount ?? asyncCount.valueOrNull ?? 0;

    return IconButton(
      onPressed: () async {
        await context.push('/notifications');
        ref.invalidate(unreadNotificationsProvider);
        ref.invalidate(notificationsListProvider);
        ref.invalidate(donorDashboardProvider);
      },
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: kError,
        child: Icon(
          Icons.notifications_outlined,
          color: IconTheme.of(context).color ?? kTextPrimary,
          size: iconSize,
        ),
      ),
    );
  }
}
