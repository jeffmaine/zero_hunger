import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'token_storage.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiService(storage);
});

class ApiException implements Exception {
  ApiException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

class ApiService {
  ApiService(this._storage) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (usesNgrok) {
      // Required for ngrok free tier — otherwise responses may be HTML warning pages.
      headers['ngrok-skip-browser-warning'] = 'true';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: headers,
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (usesNgrok) {
            options.headers['ngrok-skip-browser-warning'] = 'true';
          }
          final token = await _storage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['retried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['retried'] = true;
              opts.headers['Authorization'] =
                  'Bearer ${await _storage.readAccessToken()}';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {}
            }
            await _storage.clearTokens();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {'retried': true}),
      );
      final data = res.data as Map<String, dynamic>;
      await _storage.saveTokens(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) {
        final details = data['details'];
        if (details is Map && details['detail'] is List) {
          final list = details['detail'] as List;
          if (list.isNotEmpty && list.first is Map) {
            final first = list.first as Map;
            final field = first['field'];
            final fieldMsg = first['message'];
            if (field != null && fieldMsg != null) {
              return '$msg ($field: $fieldMsg)';
            }
          }
        }
        return msg;
      }
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return '${first['loc']}: ${first['msg']}';
        }
        return first.toString();
      }
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach API at $apiBaseUrl.\n'
          'Start backend: cd backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000';
    }
    return e.message ?? 'Something went wrong';
  }

  Future<bool> pingHealth() async {
    try {
      final res = await _dio.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          extra: {'retried': true},
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
