import 'dart:developer' as developer;
import '../config/app_config.dart';

enum LogLevel { debug, info, warning, error, fatal }

class Logger {
  static const String _name = 'ChoirManagement';

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!AppConfig.enableLogging &&
        level != LogLevel.error &&
        level != LogLevel.fatal) {
      return;
    }

    final String logLevel = level.toString().split('.').last.toUpperCase();
    final String timestamp = DateTime.now().toIso8601String();
    final String logMessage = '[$timestamp] [$logLevel] $message';

    // Use developer.log for better debugging support
    developer.log(
      message,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: _name,
      error: error,
      stackTrace: stackTrace,
    );

    // In development, also print to console for easier debugging
    if (AppConfig.isDevelopment) {
      // ignore: avoid_print
      print(logMessage);
      if (error != null) {
        // ignore: avoid_print
        print('Error: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('StackTrace: $stackTrace');
      }
    }
  }

  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  // Convenience methods for common scenarios
  static void apiCall(String endpoint, {Map<String, dynamic>? params}) {
    debug('API Call: $endpoint', params);
  }

  static void apiResponse(String endpoint, {dynamic response}) {
    debug('API Response: $endpoint', response);
  }

  static void apiError(
    String endpoint,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    Logger.error('API Error: $endpoint', error, stackTrace);
  }

  static void userAction(String action, {Map<String, dynamic>? context}) {
    info('User Action: $action', context);
  }

  static void navigation(String from, String to) {
    debug('Navigation: $from -> $to');
  }

  static void performance(String operation, Duration duration) {
    debug('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  static void database(String operation, {Map<String, dynamic>? params}) {
    debug('Database: $operation', params);
  }

  static void auth(String operation, {String? userId}) {
    info('Auth: $operation', userId != null ? {'userId': userId} : null);
  }

  static void exception(
    String context,
    dynamic exception, [
    StackTrace? stackTrace,
  ]) {
    error('Exception in $context', exception, stackTrace);
  }
}
