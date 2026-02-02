import 'package:flutter/material.dart';
import 'dart:developer' as developer;

enum ErrorType {
  storage,
  validation,
  network,
  permission,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, details: $details)';
  }
}

class ErrorHandler {
  static void handleError(AppError error, {BuildContext? context}) {
    // Log the error
    _logError(error);

    // Show user-friendly message if context is available
    if (context != null) {
      _showErrorToUser(context, error);
    }
  }

  static void _logError(AppError error) {
    developer.log(
      error.message,
      name: 'TravelTimeLogger.${error.type.name}',
      level: _getLogLevel(error.type),
      error: error.originalError,
      stackTrace: error.stackTrace,
    );
  }

  static int _getLogLevel(ErrorType type) {
    switch (type) {
      case ErrorType.storage:
      case ErrorType.network:
        return 1000; // SEVERE
      case ErrorType.validation:
        return 900; // WARNING
      case ErrorType.permission:
        return 800; // INFO
      case ErrorType.unknown:
        return 1000; // SEVERE
    }
  }

  static void _showErrorToUser(BuildContext context, AppError error) {
    final userMessage = _getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 4),
        action: error.type == ErrorType.storage
            ? SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  // Could implement retry logic here
                },
              )
            : null,
      ),
    );
  }

  static String _getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.storage:
        return 'Unable to save data. Please try again.';
      case ErrorType.validation:
        return error.message; // Validation messages are already user-friendly
      case ErrorType.network:
        return 'Network error. Please check your connection.';
      case ErrorType.permission:
        return 'Permission required. Please grant access in settings.';
      case ErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.storage:
      case ErrorType.network:
      case ErrorType.unknown:
        return Colors.red;
      case ErrorType.validation:
        return Colors.orange;
      case ErrorType.permission:
        return Colors.blue;
    }
  }

  // Specific error handlers
  static AppError handleStorageError(dynamic error, [StackTrace? stackTrace]) {
    return AppError(
      type: ErrorType.storage,
      message: 'Storage operation failed',
      details: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static AppError handleValidationError(String message) {
    return AppError(
      type: ErrorType.validation,
      message: message,
    );
  }

  static AppError handleNetworkError(dynamic error, [StackTrace? stackTrace]) {
    return AppError(
      type: ErrorType.network,
      message: 'Network operation failed',
      details: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static AppError handlePermissionError(String permission) {
    return AppError(
      type: ErrorType.permission,
      message: 'Permission required: $permission',
    );
  }

  static AppError handleUnknownError(dynamic error, [StackTrace? stackTrace]) {
    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred',
      details: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}

// Extension to make error handling easier
extension ErrorHandlerExtension on BuildContext {
  void handleError(AppError error) {
    ErrorHandler.handleError(error, context: this);
  }

  void showError(String message, {ErrorType type = ErrorType.unknown}) {
    final error = AppError(type: type, message: message);
    ErrorHandler.handleError(error, context: this);
  }
}
