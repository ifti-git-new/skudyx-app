import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioDebugInterceptor extends Interceptor {
  final int maxBodyChars;
  final bool logHeaders;
  final bool logRequestBody;
  final bool logResponseBody;

  /// Keys that will be masked anywhere in request/response JSON maps.
  final Set<String> redactedKeys;

  DioDebugInterceptor({
    this.maxBodyChars = 8000,
    this.logHeaders = true,
    this.logRequestBody = true,
    this.logResponseBody = true,
    Set<String>? redactedKeys,
  }) : redactedKeys =
           redactedKeys ??
           {
             'password',
             'accessToken',
             'refreshToken',
             'currentToken',
             'token',
             'authorization',
           };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(options);

    debugPrint('┌────────────────────────────────────────────');
    debugPrint('│ --> ${options.method} ${options.uri}');

    if (logHeaders) {
      final safeHeaders = Map<String, dynamic>.from(options.headers);
      // Don’t print bearer token
      safeHeaders.removeWhere((k, _) => k.toLowerCase() == 'authorization');
      debugPrint('│ Headers: ${_pretty(safeHeaders)}');
    }

    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query: ${_pretty(_sanitize(options.queryParameters))}');
    }

    if (logRequestBody) {
      debugPrint(
        '│ Body: ${_stringify(_sanitize(_requestBody(options.data)))}',
      );
    }

    debugPrint('│ --> END');
    debugPrint('└────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(response);

    debugPrint('┌────────────────────────────────────────────');
    debugPrint('│ <-- ${response.statusCode} ${response.requestOptions.uri}');

    if (logResponseBody) {
      debugPrint('│ Response: ${_stringify(_sanitize(response.data))}');
    }

    debugPrint('│ <-- END');
    debugPrint('└────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) return handler.next(err);

    debugPrint('┌────────────────────────────────────────────');
    debugPrint(
      '│ <-- ERROR ${err.type} ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    debugPrint('│ Message: ${err.message}');
    debugPrint('│ Error: ${err.error}');
    if (err.response != null) {
      debugPrint('│ Status: ${err.response?.statusCode}');
      debugPrint('│ Response: ${_stringify(_sanitize(err.response?.data))}');
    }
    debugPrint('│ <-- END ERROR');
    debugPrint('└────────────────────────────────────────────');
    handler.next(err);
  }

  Object? _requestBody(Object? data) {
    // If you use FormData later, avoid dumping it fully
    if (data is FormData) {
      return {
        'type': 'FormData',
        'fields': data.fields.map((e) => {e.key: e.value}).toList(),
        'files': data.files.map((e) => e.key).toList(),
      };
    }
    return data;
  }

  Object? _sanitize(Object? data) {
    if (data is Map) {
      final out = <String, dynamic>{};
      data.forEach((key, value) {
        final k = key.toString();
        if (redactedKeys.contains(k) ||
            redactedKeys.contains(k.toLowerCase())) {
          out[k] = '<redacted>';
        } else {
          out[k] = _sanitize(value);
        }
      });
      return out;
    }
    if (data is List) {
      return data.map(_sanitize).toList();
    }
    return data;
  }

  String _stringify(Object? data) {
    String s;
    try {
      s = _pretty(data);
    } catch (_) {
      s = data.toString();
    }
    if (s.length > maxBodyChars) {
      return '${s.substring(0, maxBodyChars)}... <truncated>';
    }
    return s;
  }

  String _pretty(Object? data) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
