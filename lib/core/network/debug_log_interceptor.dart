import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A Dio interceptor that logs detailed request/response information
/// in debug builds only. In release builds it is a no-op.
///
/// Logs include:
/// - Request method, URL, headers, and body
/// - Response status, headers, and body (truncated if large)
/// - Error details including response body
class DebugLogInterceptor extends Interceptor {
  /// Maximum bytes of response/request body to log.
  static const int _maxBodyLength = 2048;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) return super.onRequest(options, handler);

    _logBox('→ ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      _logHeaders(options.headers, 'Req Headers');
    }
    if (options.data != null) {
      _logBody(options.data, 'Req Body');
    }
    if (options.queryParameters.isNotEmpty) {
      _log('${_tag}Query: ${_truncate(options.queryParameters.toString())}');
    }
    _log('$_tag─────────────────────────────────────');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!kDebugMode) return super.onResponse(response, handler);

    final status = response.statusCode ?? '??';
    final statusLabel = response.statusMessage != null
        ? '$status ${response.statusMessage}'
        : '$status';
    _logBox(
      '← $statusLabel ${response.requestOptions.method} ${response.requestOptions.uri}',
    );

    if (response.headers.map.isNotEmpty) {
      _logHeaders(response.headers.map, 'Res Headers');
    }
    if (response.data != null) {
      _logBody(response.data, 'Res Body');
    }
    _log('$_tag─────────────────────────────────────');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) return super.onError(err, handler);

    final status = err.response?.statusCode ?? 'N/A';
    _logBox('✗ $status ${err.requestOptions.method} ${err.requestOptions.uri}');
    _log('$_tag Error: ${err.type} — ${err.message}');

    if (err.response?.data != null) {
      _logBody(err.response!.data, 'Error Body');
    }
    _log('$_tag─────────────────────────────────────');
    super.onError(err, handler);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static const String _tag = '  ';

  void _log(String message) => debugPrint(message);

  void _logBox(String title) {
    _log('┌─────────────────────────────────────────');
    _log('│ HTTP $title');
    _log('└─────────────────────────────────────────');
  }

  void _logHeaders(Map<String, dynamic> headers, String label) {
    _log('$_tag$label:');
    // Mask sensitive headers
    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      final value =
          (key.contains('token') ||
              key.contains('auth') ||
              key.contains('secret'))
          ? '***'
          : entry.value;
      _log('$_tag  ${entry.key}: $value');
    }
  }

  void _logBody(dynamic body, String label) {
    String bodyStr;
    if (body is String) {
      bodyStr = body;
    } else if (body is Map || body is List) {
      try {
        bodyStr = const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        bodyStr = body.toString();
      }
    } else {
      bodyStr = body.toString();
    }
    if (bodyStr.length > _maxBodyLength) {
      bodyStr =
          '${bodyStr.substring(0, _maxBodyLength)}... (${bodyStr.length} chars total)';
    }
    _log('$_tag$label:');
    for (final line in bodyStr.split('\n')) {
      _log('$_tag  $line');
    }
  }

  String _truncate(String text) {
    if (text.length > _maxBodyLength) {
      return '${text.substring(0, _maxBodyLength)}...';
    }
    return text;
  }
}
