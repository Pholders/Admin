import 'package:dio/dio.dart';

/// Pulls a human-readable message out of an API error response.
///
/// Dio throws on any non-2xx status, so the failing response body is only
/// reachable through [DioException.response]. Backends in this project report
/// failures as `{message}`, `{error: {message}}`, or a list of validation
/// strings under `errors`/`message` — all of those are handled here.
String apiErrorMessage(Object error, {required String fallback}) {
  if (error is! DioException) return fallback;

  final data = error.response?.data;
  final message = _messageFrom(data);
  if (message != null) return message;

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout) {
    return 'Could not reach the server. Check your connection and try again.';
  }
  return fallback;
}

String? _messageFrom(Object? data) {
  if (data is String && data.trim().isNotEmpty) return data.trim();

  if (data is List) {
    final parts = data.map(_messageFrom).whereType<String>().toList();
    return parts.isEmpty ? null : parts.join('\n');
  }

  if (data is Map) {
    for (final key in const ['message', 'error', 'errors', 'detail']) {
      final value = data[key];
      if (value == null) continue;
      final message = _messageFrom(value);
      if (message != null) return message;
    }
  }

  return null;
}
