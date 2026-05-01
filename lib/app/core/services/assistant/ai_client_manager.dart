import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io';
import '../../helpers/log_helper.dart';
import '../../helpers/result.dart';

class AiClientManager extends GetxService {
  http.Client? _sharedClient;
  bool _isClosed = false;

  /// Returns a shared, persistent HTTP client configured with native socket timeouts.
  /// This prevents the infamous _NativeSocket.lookup staggeredLookup crash.
  http.Client get client {
    if (_isClosed || _sharedClient == null) {
      final ioClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(seconds: 30);
        
      _sharedClient = IOClient(ioClient);
      _isClosed = false;
    }
    return _sharedClient!;
  }

  /// Resets the client (useful when network changes or provider changes)
  void resetClient() {
    _sharedClient?.close();
    _sharedClient = null;
    _isClosed = true;
  }

  @override
  void onClose() {
    resetClient();
    super.onClose();
  }

  /// Performs a POST network request with Exponential Backoff Retries
  Future<Result<http.Response>> postWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        final reqFuture = client.post(uri, headers: headers, body: body);
        // 🛡️ Prevent background unhandled NativeSocket crashes if timeout occurs first
        reqFuture.catchError((_) => http.Response('', 408));
        
        final response = await reqFuture.timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return Result.success(response);
        }

        // Check if retryable (429 Too Many Requests or 5xx Server Errors)
        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempts >= maxRetries) {
            return Result.failure('Server Error ${response.statusCode}');
          }
          final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
          talker.warning('⚠️ AI POST Request failed (${response.statusCode}). Retrying in ${backoffDelay.inMilliseconds}ms...');
          await Future.delayed(backoffDelay);
          continue;
        }

        // Non-retryable error (e.g. 400 Bad Request, 401 Unauthorized)
        return Result.failure('HTTP Error ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        if (attempts >= maxRetries) {
          return Result.failure('Request timed out after $maxRetries attempts');
        }
        final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
        talker.warning('⚠️ AI POST Request timed out. Retrying in ${backoffDelay.inMilliseconds}ms...');
        await Future.delayed(backoffDelay);
      } catch (e) {
        if (attempts >= maxRetries) {
          return Result.failure(e.toString());
        }
        final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
        talker.warning('⚠️ AI POST Network Error. Retrying in ${backoffDelay.inMilliseconds}ms...');
        await Future.delayed(backoffDelay);
      }
    }
    return Result.failure('Exhausted all retries');
  }

  /// Performs a GET network request with Exponential Backoff Retries
  Future<Result<http.Response>> getWithRetry(
    Uri uri, {
    required Map<String, String> headers,
    int maxRetries = 3,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        final reqFuture = client.get(uri, headers: headers);
        // 🛡️ Prevent background unhandled NativeSocket crashes if timeout occurs first
        reqFuture.catchError((_) => http.Response('', 408));
        
        final response = await reqFuture.timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return Result.success(response);
        }

        // Check if retryable (429 Too Many Requests or 5xx Server Errors)
        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempts >= maxRetries) {
            return Result.failure('Server Error ${response.statusCode}');
          }
          final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
          talker.warning('⚠️ AI GET Request failed (${response.statusCode}). Retrying in ${backoffDelay.inMilliseconds}ms...');
          await Future.delayed(backoffDelay);
          continue;
        }

        // Non-retryable error
        return Result.failure('HTTP Error ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        if (attempts >= maxRetries) {
          return Result.failure('Request timed out after $maxRetries attempts');
        }
        final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
        talker.warning('⚠️ AI GET Request timed out. Retrying in ${backoffDelay.inMilliseconds}ms...');
        await Future.delayed(backoffDelay);
      } catch (e) {
        if (attempts >= maxRetries) {
          return Result.failure(e.toString());
        }
        final backoffDelay = Duration(milliseconds: 500 * (1 << (attempts - 1)));
        talker.warning('⚠️ AI GET Network Error. Retrying in ${backoffDelay.inMilliseconds}ms...');
        await Future.delayed(backoffDelay);
      }
    }
    return Result.failure('Exhausted all retries');
  }
}
