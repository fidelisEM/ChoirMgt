import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum ErrorType {
  network,
  database,
  validation,
  authentication,
  permission,
  unknown
}

class AppError {

  AppError({
    required this.message,
    this.technicalMessage,
    required this.type,
    this.code,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final String message;
  final String? technicalMessage;
  final ErrorType type;
  final String? code;
  final DateTime timestamp;

  @override
  String toString() => 'AppError($type): $message';
}

class ErrorService {
  factory ErrorService() => _instance;
  ErrorService._internal();
  static final ErrorService _instance = ErrorService._internal();

  final List<AppError> _errorLog = [];

  void logError(AppError error) {
    _errorLog.add(error);
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('🔴 ${error.type.name.toUpperCase()}: ${error.message}');
      if (error.technicalMessage != null) {
        debugPrint('   Technical: ${error.technicalMessage}');
      }
    }

    // In production, you would send to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  void showErrorSnackBar(BuildContext context, AppError error) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () => messenger.hideCurrentSnackBar(),
          textColor: Colors.white,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void showSuccessSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<AppError> get recentErrors => _errorLog
      .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 60)
      .toList();

  AppError createNetworkError(String message, {String? technicalMessage}) {
    return AppError(
      message: message,
      technicalMessage: technicalMessage,
      type: ErrorType.network,
    );
  }

  AppError createDatabaseError(String message, {String? technicalMessage}) {
    return AppError(
      message: message,
      technicalMessage: technicalMessage,
      type: ErrorType.database,
    );
  }

  AppError createValidationError(String message, {String? field}) {
    return AppError(
      message: message,
      technicalMessage: field != null ? 'Field: $field' : null,
      type: ErrorType.validation,
    );
  }

  AppError createAuthError(String message, {String? technicalMessage}) {
    return AppError(
      message: message,
      technicalMessage: technicalMessage,
      type: ErrorType.authentication,
    );
  }
}

// Extension for easier error handling in widgets
extension ContextErrorHandling on BuildContext {
  void showError(AppError error) {
    ErrorService().showErrorSnackBar(this, error);
  }

  void showErrorMessage(String message, {ErrorType type = ErrorType.unknown}) {
    final error = AppError(message: message, type: type);
    ErrorService().logError(error);
    showError(error);
  }

  void showSuccess(String message) {
    ErrorService().showSuccessSnackBar(this, message);
  }
}