import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../../helpers/result.dart';

// ─── Isolate-safe top-level functions ──────────────────
// These MUST be top-level to be passed to compute().

/// Performs a full HTTP POST inside a separate Isolate, completely
/// isolating the main thread from any native socket / DNS crashes.
Future<_IsolateHttpResult> _isolateHttpPost(_IsolateHttpArgs args) async {
  try {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)  // 5s: 3 retries = 15s, safely under controller's 30s
      ..idleTimeout = const Duration(seconds: 10)
      ..badCertificateCallback = (_, _, _) => false;

    final ioClient = IOClient(httpClient);

    try {
      // 🛡️ Use ioClient.post() instead of send()+fromStream().
      // send() only covers headers — fromStream() body download has NO timeout
      // and hangs until the outer 30s controller timeout fires.
      // post() applies a single timeout to the FULL exchange (headers + body).
      final response = await ioClient
          .post(args.uri, headers: args.headers, body: args.body)
          .timeout(args.timeout);

      return _IsolateHttpResult(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on TimeoutException {
      return const _IsolateHttpResult.failure('timeout_error');
    } on http.ClientException catch (e) {
      // 🛡️ Catches _ClientSocketException (HttpClient.connectionTimeout)
      // which wraps SocketException in a ClientException from package:http.
      // 'on SocketException' does NOT catch this — this handler is required.
      return _IsolateHttpResult.failure('socket_error: ${e.message}');
    } on SocketException catch (e) {
      return _IsolateHttpResult.failure('socket_error: ${e.message}');
    } on HandshakeException catch (e) {
      return _IsolateHttpResult.failure('tls_error: ${e.message}');
    } catch (e) {
      return _IsolateHttpResult.failure('socket_error: $e'); // treat unknowns as retryable
    } finally {
      ioClient.close();
      httpClient.close(force: true);
    }
  } catch (e) {
    return _IsolateHttpResult.failure('isolate_init_error: $e');
  }
}

/// Performs a full HTTP GET inside a separate Isolate.
Future<_IsolateHttpResult> _isolateHttpGet(_IsolateHttpArgs args) async {
  try {
    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 10);

    final ioClient = IOClient(httpClient);
    try {
      final response = await ioClient
          .get(args.uri, headers: args.headers)
          .timeout(args.timeout);
      return _IsolateHttpResult(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on TimeoutException {
      return const _IsolateHttpResult.failure('timeout_error');
    } on http.ClientException catch (e) {
      return _IsolateHttpResult.failure('socket_error: ${e.message}');
    } on SocketException catch (e) {
      return _IsolateHttpResult.failure('socket_error: ${e.message}');
    } catch (e) {
      return _IsolateHttpResult.failure('socket_error: $e');
    } finally {
      ioClient.close();
      httpClient.close(force: true);
    }
  } catch (e) {
    return _IsolateHttpResult.failure('isolate_init_error: $e');
  }
}

Map<String, dynamic> _aiClientManagerDecodeJson(String source) {
  try {
    return jsonDecode(source) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

// ─── Isolate Data Transfer Objects ─────────────────────

class _IsolateHttpArgs {
  final Uri uri;
  final Map<String, String> headers;
  final String body;
  final Duration timeout;

  const _IsolateHttpArgs({
    required this.uri,
    required this.headers,
    required this.body,
    required this.timeout,
  });
}

class _IsolateHttpResult {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final String? error;

  bool get isSuccess => error == null && statusCode >= 200 && statusCode < 300;

  const _IsolateHttpResult({
    required this.statusCode,
    required this.body,
    required this.headers,
  }) : error = null;

  const _IsolateHttpResult.failure(this.error)
      : statusCode = 0,
        body = '',
        headers = const {};
}

// ─── Main AiClientManager ───────────────────────────────

/// 🛡️ Reliability Engineer's Choice: Comprehensive Network Guard
/// 
/// All HTTP requests are executed in separate Isolates via `compute()`,
/// making it IMPOSSIBLE for native socket / DNS crashes to reach the
/// main thread or the Flutter UI.
class AiClientManager extends GetxService {
  // Kept for backward-compat but no longer used for actual requests.
  http.Client? _sharedClient;
  bool _isClosed = false;

  final _failureCount = 0.obs;
  final _lastFailureTime = Rxn<DateTime>();
  static const int _maxFailuresBeforeTrip = 5;
  static const Duration _resetDuration = Duration(minutes: 2);

  AiClientManager._();
  static final AiClientManager _instance = AiClientManager._();
  static AiClientManager get instance => _instance;
  factory AiClientManager() => _instance;

  Duration? get circuitRemainingCooldown {
    if (_failureCount.value < _maxFailuresBeforeTrip || _lastFailureTime.value == null) return null;
    final diff = DateTime.now().difference(_lastFailureTime.value!);
    if (diff > _resetDuration) return null;
    return _resetDuration - diff;
  }

  bool get isCircuitOpen {
    if (_failureCount.value >= _maxFailuresBeforeTrip) {
      if (_lastFailureTime.value != null &&
          DateTime.now().difference(_lastFailureTime.value!) > _resetDuration) {
        _failureCount.value = 0;
        return false;
      }
      return true;
    }
    return false;
  }

  // Legacy client getter — kept for any future use but postWithRetry no longer uses it.
  http.Client get client {
    if (_isClosed || _sharedClient == null) {
      final ioClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..idleTimeout = const Duration(seconds: 10);
      _sharedClient = IOClient(ioClient);
      _isClosed = false;
    }
    return _sharedClient!;
  }

  void resetClient() {
    try { _sharedClient?.close(); } catch (_) {}
    _sharedClient = null;
    _isClosed = true;
  }

  void resetFailureCount() {
    _failureCount.value = 0;
    _lastFailureTime.value = null;
  }

  /// 🚀 DEFINITIVE FIX: Runs the ENTIRE HTTP POST (including DNS resolution
  /// and TCP connect) inside a separate Isolate via `compute()`.
  ///
  /// This guarantees the main thread NEVER touches native sockets.
  /// `_NativeSocket.lookup` crashes become impossible to propagate to Flutter.
  Future<Result<http.Response>> postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (isCircuitOpen) return Result.failure('circuit_open_error');

    final args = _IsolateHttpArgs(
      uri: uri,
      headers: headers,
      body: body,
      timeout: timeout,
    );

    int attempts = 0;
    while (attempts < maxRetries) {
      attempts++;
      try {
        // 🔒 ENTIRE request in Isolate — main thread is 100% safe
        // 15s hard cap: DNS can hang 30s+ even with 5s connectionTimeout
        // (connectionTimeout only starts AFTER DNS resolves)
        final result = await compute(_isolateHttpPost, args)
            .timeout(const Duration(seconds: 15));

        if (result.isSuccess) {
          _failureCount.value = 0;
          // Reconstruct http.Response for backward compat
          return Result.success(http.Response(result.body, result.statusCode, headers: result.headers));
        }

        if (result.error != null) {
          final err = result.error!;
          if (err.contains('socket_error')) {
            _failureCount.value++;
            _lastFailureTime.value = DateTime.now();
            if (attempts >= maxRetries) return Result.failure('network_unreachable');
            await Future.delayed(Duration(seconds: attempts));
            continue;
          }
          if (err.contains('timeout_error')) return Result.failure('timeout_error');
          return Result.failure(err);
        }

        // HTTP error status
        final statusCode = result.statusCode;
        if (statusCode == 429 || statusCode >= 500) {
          await Future.delayed(Duration(seconds: attempts));
          continue;
        }
        return Result.failure('HTTP $statusCode: ${result.body}');

      } on TimeoutException {
        // compute().timeout(15s) fired — DNS or connection hung inside isolate
        _failureCount.value++;
        _lastFailureTime.value = DateTime.now();
        if (attempts >= maxRetries) return Result.failure('timeout_error');
        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        // compute() itself failed — very rare
        if (attempts >= maxRetries) return Result.failure('compute_error: $e');
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    return Result.failure('max_retries_reached');
  }

  /// 🔒 GET also runs fully inside an Isolate.
  Future<Result<http.Response>> getWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    int maxRetries = 2,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (isCircuitOpen) return Result.failure('circuit_open_error');

    final args = _IsolateHttpArgs(
      uri: uri,
      headers: headers,
      body: '',
      timeout: timeout,
    );

    int attempts = 0;
    while (attempts < maxRetries) {
      attempts++;
      try {
        final result = await compute(_isolateHttpGet, args)
            .timeout(const Duration(seconds: 15));

        if (result.isSuccess) {
          return Result.success(http.Response(result.body, result.statusCode, headers: result.headers));
        }

        if (result.error != null) {
          if (attempts >= maxRetries) return Result.failure(result.error!);
          await Future.delayed(Duration(milliseconds: 500 * attempts));
          continue;
        }

        if (attempts >= maxRetries) return Result.failure('HTTP ${result.statusCode}');
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } catch (e) {
        if (attempts >= maxRetries) return Result.failure('compute_error: $e');
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }
    return Result.failure('max_retries_reached');
  }

  Future<Map<String, dynamic>> parseJsonSafe(String source) async {
    try {
      return await compute(_aiClientManagerDecodeJson, source);
    } catch (e) {
      return {};
    }
  }
}
