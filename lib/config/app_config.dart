import 'package:flutter/foundation.dart' show kReleaseMode;

import 'env_config.dart';

enum Environment { development, staging, production }

class AppConfig {
  static Environment _environment = Environment.development;
  static final EnvConfig _envConfig = EnvConfig.instance;
  
  // Initialize configuration
  static Future<void> initialize() async {
    await _envConfig.initialize();
    detectEnvironment();
  }
  
  // Environment detection from the ENVIRONMENT dart-define (EnvConfig already
  // falls back to a build-mode-correct default of its own if it's unset).
  static void detectEnvironment() {
    final envString = _envConfig.getString('ENVIRONMENT').toLowerCase();
    switch (envString) {
      case 'production':
        _environment = Environment.production;
        break;
      case 'staging':
        _environment = Environment.staging;
        break;
      case 'development':
        _environment = Environment.development;
        break;
      default:
        _environment = kReleaseMode ? Environment.production : Environment.development;
        break;
    }
  }
  
  static Environment get environment => _environment;
  
  static void setEnvironment(Environment env) {
    _environment = env;
  }
  
  // App Configuration
  static const String appName = 'Choir Management System';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.choirmanagement.app';
  
  // API Configuration - Now loaded from environment
  static String get supabaseUrl => _envConfig.getString('SUPABASE_URL');
  static String get supabaseAnonKey => _envConfig.getString('SUPABASE_ANON_KEY');
  
  // Validate configuration
  static bool get isConfigValid => _envConfig.validateConfig();
  
  // Feature flags
  static bool get enableLogging {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }
  
  static bool get enableCrashReporting {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  static bool get enableAnalytics {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return false;
      case Environment.production:
        return true;
    }
  }
  
  static bool get enableDebugMode {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }
  
  // Cache Configuration
  static Duration get cacheTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.production:
        return const Duration(hours: 1);
    }
  }
  
  // Network Configuration
  static Duration get networkTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 45);
      case Environment.production:
        return const Duration(seconds: 60);
    }
  }
  
  // Security Configuration
  static bool get requireSSL {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  static int get sessionTimeout {
    switch (_environment) {
      case Environment.development:
        return 24; // hours
      case Environment.staging:
        return 8;
      case Environment.production:
        return 4;
    }
  }
  
  // Performance Configuration
  static int get maxImageSize {
    switch (_environment) {
      case Environment.development:
        return 10 * 1024 * 1024; // 10MB
      case Environment.staging:
        return 5 * 1024 * 1024; // 5MB
      case Environment.production:
        return 2 * 1024 * 1024; // 2MB
    }
  }
  
  static int get maxCacheSize {
    switch (_environment) {
      case Environment.development:
        return 100 * 1024 * 1024; // 100MB
      case Environment.staging:
        return 75 * 1024 * 1024; // 75MB
      case Environment.production:
        return 50 * 1024 * 1024; // 50MB
    }
  }
  
  // Notification Configuration
  static bool get enablePushNotifications {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  // Database Configuration
  static bool get enableOfflineMode {
    return false; // Currently not implemented
  }
  
  static int get maxRetryAttempts {
    switch (_environment) {
      case Environment.development:
        return 5;
      case Environment.staging:
        return 3;
      case Environment.production:
        return 3;
    }
  }
  
  // Logging Configuration
  static String get logLevel {
    switch (_environment) {
      case Environment.development:
        return 'DEBUG';
      case Environment.staging:
        return 'INFO';
      case Environment.production:
        return 'ERROR';
    }
  }
  
  // UI Configuration
  static bool get showDebugBanner {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }
  
  static bool get enableInspectorSelect {
    switch (_environment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return false;
      case Environment.production:
        return false;
    }
  }
  
  // Validation
  static bool get strictValidation {
    switch (_environment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }
  
  // Get environment name as string
  static String get environmentName {
    return _environment.toString().split('.').last;
  }
  
  // Check if development
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  // App Store Configuration
  static String get appStoreUrl {
    switch (_environment) {
      case Environment.development:
        return '';
      case Environment.staging:
        return '';
      case Environment.production:
        return 'https://apps.apple.com/app/choir-management-system/id123456789';
    }
  }
  
  static String get playStoreUrl {
    switch (_environment) {
      case Environment.development:
        return '';
      case Environment.staging:
        return '';
      case Environment.production:
        return 'https://play.google.com/store/apps/details?id=com.choirmanagement.app';
    }
  }
  
  // Support Configuration
  static String get supportEmail {
    switch (_environment) {
      case Environment.development:
        return 'dev@choirmanagement.com';
      case Environment.staging:
        return 'staging@choirmanagement.com';
      case Environment.production:
        return 'support@choirmanagement.com';
    }
  }
  
  static String get privacyPolicyUrl {
    return 'https://choirmanagement.com/privacy';
  }
  
  static String get termsOfServiceUrl {
    return 'https://choirmanagement.com/terms';
  }
  
  // Log current configuration (for debugging)
  static void logConfig() {
    if (enableLogging && isDevelopment) {
      // Use proper logging instead of print in production
      final config = {
        'environment': environmentName.toUpperCase(),
        'appVersion': appVersion,
        'debugMode': enableDebugMode,
        'logging': enableLogging,
        'analytics': enableAnalytics,
        'crashReporting': enableCrashReporting,
        'sessionTimeout': '${sessionTimeout}h',
        'cacheTimeout': cacheTimeout.toString(),
        'networkTimeout': networkTimeout.toString(),
      };
      
      // This would integrate with the Logger class in production
      for (final entry in config.entries) {
        assert(() {
          // ignore: avoid_print
          print('${entry.key}: ${entry.value}');
          return true;
        }());
      }
    }
  }
}