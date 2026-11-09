import 'package:flutter/foundation.dart' show kReleaseMode;

// All values below are compile-time constants sourced from --dart-define
// (or --dart-define-from-file). Nothing here is a real secret — this file
// just declares which keys exist and their non-sensitive fallbacks.
// Real Supabase URL/anon key must be supplied at build time; there is no
// hardcoded fallback for them so a misconfigured build fails loudly instead
// of silently talking to someone's live project.
const String _environmentDefine = String.fromEnvironment('ENVIRONMENT');
const String _appName = String.fromEnvironment(
  'APP_NAME',
  defaultValue: 'Choir Management System',
);
const String _appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const bool _enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS');
const bool _enableCrashReporting = bool.fromEnvironment(
  'ENABLE_CRASH_REPORTING',
);
const bool _enableLogging = bool.fromEnvironment(
  'ENABLE_LOGGING',
  defaultValue: !kReleaseMode,
);
const int _sessionTimeout = int.fromEnvironment(
  'SESSION_TIMEOUT',
  defaultValue: 4,
);
const String _supportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: 'support@choirmanagement.com',
);
const String _privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: 'https://choirmanagement.com/privacy',
);
const String _termsOfServiceUrl = String.fromEnvironment(
  'TERMS_OF_SERVICE_URL',
  defaultValue: 'https://choirmanagement.com/terms',
);

class EnvConfig {
  // Private constructor
  EnvConfig._();

  static final EnvConfig _instance = EnvConfig._();
  static EnvConfig get instance => _instance;

  // Environment variables cache
  final Map<String, String> _cache = {};

  // Initialize environment configuration
  Future<void> initialize() async {
    _loadDefaults();
  }

  void _loadDefaults() {
    _cache
      ..clear()
      ..addAll({
        'ENVIRONMENT': _environmentDefine.isNotEmpty
            ? _environmentDefine
            : (kReleaseMode ? 'production' : 'development'),
        'APP_NAME': _appName,
        'APP_VERSION': _appVersion,
        'SUPABASE_URL': _supabaseUrl,
        'SUPABASE_ANON_KEY': _supabaseAnonKey,
        'ENABLE_ANALYTICS': _enableAnalytics.toString(),
        'ENABLE_CRASH_REPORTING': _enableCrashReporting.toString(),
        'ENABLE_LOGGING': _enableLogging.toString(),
        'SESSION_TIMEOUT': _sessionTimeout.toString(),
        'SUPPORT_EMAIL': _supportEmail,
        'PRIVACY_POLICY_URL': _privacyPolicyUrl,
        'TERMS_OF_SERVICE_URL': _termsOfServiceUrl,
      });
  }

  // Get string value
  String getString(String key, {String? defaultValue}) {
    // For web, we only use cached defaults (environment variables not accessible)
    // For mobile/desktop, environment variables would be handled differently
    return _cache[key] ?? defaultValue ?? '';
  }

  // Get boolean value
  bool getBool(String key, {bool defaultValue = false}) {
    final value = getString(key).toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }

  // Get integer value
  int getInt(String key, {int defaultValue = 0}) {
    final value = getString(key);
    return int.tryParse(value) ?? defaultValue;
  }

  // Get double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = getString(key);
    return double.tryParse(value) ?? defaultValue;
  }

  // Check if environment is production
  bool get isProduction =>
      getString('ENVIRONMENT').toLowerCase() == 'production';
  bool get isStaging => getString('ENVIRONMENT').toLowerCase() == 'staging';
  bool get isDevelopment =>
      getString('ENVIRONMENT').toLowerCase() == 'development' ||
      getString('ENVIRONMENT').isEmpty; // Default to development

  // Validate required configuration
  bool validateConfig() {
    final requiredKeys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

    for (final key in requiredKeys) {
      final value = getString(key);
      if (value.isEmpty ||
          value.contains('your-') ||
          value.contains('placeholder')) {
        return false;
      }
    }

    return true;
  }

  // Get configuration summary (for debugging - no sensitive data)
  Map<String, dynamic> getConfigSummary() {
    return {
      'environment': getString('ENVIRONMENT'),
      'appName': getString('APP_NAME'),
      'appVersion': getString('APP_VERSION'),
      'enableAnalytics': getBool('ENABLE_ANALYTICS'),
      'enableLogging': getBool('ENABLE_LOGGING'),
      'enableCrashReporting': getBool('ENABLE_CRASH_REPORTING'),
      'sessionTimeout': getInt('SESSION_TIMEOUT'),
      'supabaseConfigured': !getString('SUPABASE_URL').contains('your-'),
    };
  }

  // Override for testing
  void setTestValue(String key, String value) {
    _cache[key] = value;
  }

  // Clear test values
  void clearTestValues() {
    _loadDefaults();
  }
}
