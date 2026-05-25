import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/json_parse.dart';
import '../models/app_notification.dart';
import 'api_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiServiceProvider));
});

class NotificationService {
  NotificationService(this._api);

  final ApiService _api;

  Future<NotificationListResult> fetchList({bool unreadOnly = false}) async {
    try {
      final res = await _api.dio.get(
        '/notifications',
        queryParameters: {if (unreadOnly) 'unread_only': true},
      );
      return NotificationListResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final res = await _api.dio.get('/notifications/unread-count');
      return parseInt((res.data as Map<String, dynamic>)['unread_count']);
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.post('/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException(_api.parseError(e));
    }
  }
}
