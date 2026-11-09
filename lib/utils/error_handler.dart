import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'logger.dart';

enum ErrorType {
  network,
  authentication,
  validation,
  database,
  permission,
  unknown,
}

class AppError {
  const AppError({
    required this.message,
    this.code,
    required this.type,
    this.originalError,
    this.stackTrace,
    this.context,
  });
  final String message;
  final String? code;
  final ErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  @override
  String toString() {
    return 'AppError: $message (Type: $type, Code: $code)';
  }
}

class ErrorHandler {
  static String handleError(dynamic error, [StackTrace? stackTrace]) {
    final appError = _parseError(error, stackTrace);

    // Log the error
    _logError(appError);

    // Return user-friendly message
    return _getUserFriendlyMessage(appError);
  }

  static AppError _parseError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }

    // Network errors
    if (error.toString().contains('NetworkException') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      return AppError(
        message: 'Network connection error',
        type: ErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Authentication errors
    if (error.toString().contains('AuthException') ||
        error.toString().contains('Invalid login credentials') ||
        error.toString().contains('User not found') ||
        error.toString().contains('Unauthorized')) {
      return AppError(
        message: 'Authentication failed',
        type: ErrorType.authentication,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Validation errors
    if (error.toString().contains('ValidationException') ||
        error.toString().contains('Invalid') ||
        error.toString().contains('Required')) {
      return AppError(
        message: 'Invalid input data',
        type: ErrorType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Database errors
    if (error.toString().contains('PostgrestException') ||
        error.toString().contains('ForeignKeyViolation') ||
        error.toString().contains('UniqueViolation')) {
      return AppError(
        message: 'Database operation failed',
        type: ErrorType.database,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Permission errors
    if (error.toString().contains('PermissionException') ||
        error.toString().contains('Forbidden') ||
        error.toString().contains('Access denied')) {
      return AppError(
        message: 'Insufficient permissions',
        type: ErrorType.permission,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Unknown errors
    return AppError(
      message: error?.toString() ?? 'Unknown error occurred',
      type: ErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static void _logError(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        Logger.warning(
          'Network Error: ${error.message}',
          error.originalError,
          error.stackTrace,
        );
        break;
      case ErrorType.authentication:
        Logger.warning(
          'Auth Error: ${error.message}',
          error.originalError,
          error.stackTrace,
        );
        break;
      case ErrorType.validation:
        Logger.info('Validation Error: ${error.message}', error.originalError);
        break;
      case ErrorType.database:
        Logger.error(
          'Database Error: ${error.message}',
          error.originalError,
          error.stackTrace,
        );
        break;
      case ErrorType.permission:
        Logger.warning(
          'Permission Error: ${error.message}',
          error.originalError,
        );
        break;
      case ErrorType.unknown:
        Logger.error(
          'Unknown Error: ${error.message}',
          error.originalError,
          error.stackTrace,
        );
        break;
    }
  }

  static String _getUserFriendlyMessage(AppError error) {
    switch (error.type) {
      case ErrorType.network:
        return 'Please check your internet connection and try again.';
      case ErrorType.authentication:
        return 'Please check your credentials and try again.';
      case ErrorType.validation:
        return 'Please check your input and try again.';
      case ErrorType.database:
        return 'A system error occurred. Please try again later.';
      case ErrorType.permission:
        return 'You don\'t have permission to perform this action.';
      case ErrorType.unknown:
        if (AppConfig.isDevelopment) {
          return error.message;
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Specific error creators
  static AppError networkError(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      type: ErrorType.network,
      originalError: originalError,
    );
  }

  static AppError authenticationError(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      type: ErrorType.authentication,
      originalError: originalError,
    );
  }

  static AppError validationError(
    String message, [
    Map<String, dynamic>? context,
  ]) {
    return AppError(
      message: message,
      type: ErrorType.validation,
      context: context,
    );
  }

  static AppError databaseError(String message, [dynamic originalError]) {
    return AppError(
      message: message,
      type: ErrorType.database,
      originalError: originalError,
    );
  }

  static AppError permissionError(
    String message, [
    Map<String, dynamic>? context,
  ]) {
    return AppError(
      message: message,
      type: ErrorType.permission,
      context: context,
    );
  }

  // Handle Flutter framework errors
  static void handleFlutterError(FlutterErrorDetails details) {
    final error = AppError(
      message: 'Flutter framework error',
      type: ErrorType.unknown,
      originalError: details.exception,
      stackTrace: details.stack,
    );

    _logError(error);

    // In production, send to crash reporting service
    if (AppConfig.isProduction && AppConfig.enableCrashReporting) {
      _sendToCrashReporting(error, details.stack);
    }
  }

  // Handle async errors
  static void handleAsyncError(Object error, StackTrace stackTrace) {
    final appError = _parseError(error, stackTrace);
    _logError(appError);

    // In production, send to crash reporting service
    if (AppConfig.isProduction && AppConfig.enableCrashReporting) {
      _sendToCrashReporting(appError, stackTrace);
    }
  }

  static void _sendToCrashReporting(AppError error, StackTrace? stackTrace) {
    try {
      // Firebase Crashlytics implementation would go here
      // Example:
      // FirebaseCrashlytics.instance.recordError(
      //   error.originalError ?? error.message,
      //   stackTrace,
      //   reason: error.message,
      //   information: [
      //     'Error Type: ${error.type}',
      //     'Error Code: ${error.code}',
      //     if (error.context != null) 'Context: ${error.context}',
      //   ],
      // );

      Logger.info('Error sent to crash reporting: ${error.message}');
    } catch (e) {
      Logger.error('Failed to send error to crash reporting', e);
    }
  }
}
