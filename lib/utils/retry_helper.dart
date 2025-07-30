import 'dart:async';
import 'dart:math';
import 'error_handler.dart';

class RetryHelper {
  static const int defaultMaxRetries = 3;
  static const Duration defaultInitialDelay = Duration(milliseconds: 500);
  static const double defaultBackoffMultiplier = 2.0;

  /// Executes a function with exponential backoff retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempt++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempt > maxRetries) {
          rethrow;
        }

        // Log the retry attempt
        final appError = ErrorHandler.handleStorageError(error, stackTrace);
        ErrorHandler.handleError(appError);

        // Wait before retrying with exponential backoff
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    // This should never be reached, but just in case
    throw Exception('Retry logic failed unexpectedly');
  }

  /// Determines if an error should be retried (for storage operations)
  static bool shouldRetryStorageError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Retry on temporary storage issues
    if (errorString.contains('locked') ||
        errorString.contains('busy') ||
        errorString.contains('timeout') ||
        errorString.contains('temporary')) {
      return true;
    }

    // Don't retry on permanent errors
    if (errorString.contains('not found') ||
        errorString.contains('permission') ||
        errorString.contains('access denied') ||
        errorString.contains('invalid') ||
        errorString.contains('corrupt')) {
      return false;
    }

    // Default to retry for unknown errors
    return true;
  }

  /// Determines if a network error should be retried
  static bool shouldRetryNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Retry on temporary network issues
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('unreachable') ||
        errorString.contains('temporary')) {
      return true;
    }

    // Don't retry on client errors (4xx)
    if (errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404')) {
      return false;
    }

    // Retry on server errors (5xx)
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return true;
    }

    // Default to retry for unknown network errors
    return true;
  }

  /// Execute with jittered exponential backoff to avoid thundering herd
  static Future<T> executeWithJitteredRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    double jitterFactor = 0.1,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final random = Random();
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        if (attempt > maxRetries) {
          rethrow;
        }

        // Add jitter to prevent thundering herd
        final jitter = currentDelay.inMilliseconds * jitterFactor * random.nextDouble();
        final jitteredDelay = Duration(
          milliseconds: currentDelay.inMilliseconds + jitter.round(),
        );

        await Future.delayed(jitteredDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw Exception('Jittered retry logic failed unexpectedly');
  }

  /// Simple retry for quick operations
  static Future<T> simpleRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 2,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        if (attempt == maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Simple retry failed unexpectedly');
  }
}