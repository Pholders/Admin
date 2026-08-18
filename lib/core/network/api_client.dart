import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Keys whose values must never reach the console.
const _redactedKeys = <String>{
  'password',
  'confirmPassword',
  'confirm_password',
  'password_hash',
  'currentPassword',
  'newPassword',
  'otp',
  'otp_code',
  'token',
  'accessToken',
  'refreshToken',
};

Object? _redact(Object? data) {
  if (data is Map) {
    return {
      for (final entry in data.entries)
        entry.key: _redactedKeys.contains(entry.key.toString())
            ? '***'
            : _redact(entry.value),
    };
  }
  if (data is List) return data.map(_redact).toList();
  return data;
}

class ApiClient {
  ApiClient({String? baseUrl, Duration? timeout})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? '',
            // The API is hosted on a plan that sleeps when idle, so the first
            // request after a pause pays a cold start of well over 10s.
            connectTimeout: timeout ?? const Duration(seconds: 45),
            receiveTimeout: timeout ?? const Duration(seconds: 45),
            contentType: 'application/json',
          ),
        ) {
    if (kDebugMode) {
      // Without this, a 4xx surfaces only as "DioException [bad response]" and
      // the server's message is invisible. Credentials are masked — Dio's own
      // LogInterceptor would dump them verbatim.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('→ ${options.method} ${options.uri}');
            debugPrint('  ${_redact(options.data)}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
            debugPrint('  ${_redact(response.data)}');
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
                '✖ ${error.response?.statusCode ?? error.type} ${error.requestOptions.uri}');
            debugPrint('  ${_redact(error.response?.data) ?? error.message}');
            handler.next(error);
          },
        ),
      );
    }
  }

  final Dio dio;
}
