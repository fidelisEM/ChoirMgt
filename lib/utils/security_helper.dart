import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../config/app_config.dart';

class SecurityHelper {
  static final Random _random = Random.secure();

  // Generate secure random string
  static String generateRandomString(int length) {
    const charset =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => charset[_random.nextInt(charset.length)],
    ).join();
  }

  // Generate secure hash
  static String generateHash(String input, {String? salt}) {
    final saltToUse = salt ?? generateRandomString(16);
    final bytes = utf8.encode(input + saltToUse);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Validate password strength
  static bool isPasswordSecure(String password) {
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strengthScore = 0;
    if (hasUppercase) strengthScore++;
    if (hasLowercase) strengthScore++;
    if (hasDigit) strengthScore++;
    if (hasSpecialChar) strengthScore++;

    return strengthScore >= 3;
  }

  // Sanitize input to prevent XSS. `&` must be escaped first, otherwise the
  // `&` introduced by the other replacements (e.g. `<` -> `&lt;`) gets
  // escaped a second time into `&amp;lt;`.
  static String sanitizeInput(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  // Validate file extension
  static bool isAllowedFileType(
    String fileName,
    List<String> allowedExtensions,
  ) {
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  // Check for SQL injection patterns
  static bool containsSQLInjection(String input) {
    final sqlPatterns = [
      r'(\s|^)(select|insert|update|delete|drop|create|alter|exec|union|script)\s+',
      r'(--|#|/\*|\*/)',
      r'(\s|^)(and|or)\s+\d+=\d+',
      r"('|\x22|`)(.*?)\1\s*(=|like|in)\s*\1",
    ];

    final lowerInput = input.toLowerCase();
    for (final pattern in sqlPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowerInput)) {
        return true;
      }
    }
    return false;
  }

  // Generate session token
  static String generateSessionToken() {
    return generateRandomString(32);
  }

  // Validate session token format
  static bool isValidSessionToken(String token) {
    if (token.length != 32) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(token);
  }

  // Rate limiting helper
  static bool isRateLimited(
    String identifier,
    int maxRequests,
    Duration window,
  ) {
    // This is a simplified implementation
    // In production, you would store this in a cache or database
    return false; // Placeholder
  }

  // Validate email format (more secure version)
  static bool isValidEmailFormat(String email) {
    // More restrictive email validation to prevent injection
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email) && !containsSQLInjection(email);
  }

  // Generate secure random number
  static int generateRandomNumber(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  // Mask sensitive data for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars * 2) {
      return '*' * data.length;
    }

    final start = data.substring(0, visibleChars);
    final end = data.substring(data.length - visibleChars);
    final masked = '*' * (data.length - visibleChars * 2);

    return start + masked + end;
  }

  // Validate URL to prevent SSRF attacks
  static bool isValidURL(String url) {
    final parsedUri = Uri.tryParse(url);
    if (parsedUri?.hasScheme != true) return false;

    final uri = Uri.parse(url);

    // Only allow HTTP/HTTPS
    if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
      return false;
    }

    // Prevent localhost and private IP access
    if (AppConfig.isProduction) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' ||
          host.startsWith('127.') ||
          host.startsWith('10.') ||
          host.startsWith('172.') ||
          host.startsWith('192.168.')) {
        return false;
      }
    }

    return true;
  }

  // Content Security Policy headers
  static Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
      'Content-Security-Policy':
          "default-src 'self'; script-src 'self' 'unsafe-inline'",
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    };
  }

  // Generate API key
  static String generateAPIKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = generateRandomString(16);
    final combined = timestamp + random;
    return base64Encode(utf8.encode(combined));
  }

  // Validate user permissions
  static bool hasPermission(String userRole, String requiredPermission) {
    const adminPermissions = [
      'read',
      'write',
      'delete',
      'manage_users',
      'manage_payments',
      'manage_attendance',
      'view_reports',
    ];
    const rolePermissions = {
      'super_admin': adminPermissions,
      'admin': adminPermissions,
      // Leaders record payments and attendance for their own choir (see RLS).
      'leader': [
        'read',
        'write',
        'manage_payments',
        'manage_attendance',
        'view_reports',
      ],
      'member': ['read'],
      'guest': [],
    };

    final permissions = rolePermissions[userRole] ?? [];
    return permissions.contains(requiredPermission);
  }

  // Encrypt sensitive data (simple implementation)
  static String encryptData(String data, String key) {
    // This is a simplified implementation
    // In production, use proper encryption libraries
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final result = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      result.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(result);
  }

  // Decrypt sensitive data
  static String decryptData(String encryptedData, String key) {
    try {
      final bytes = base64Decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final result = <int>[];

      for (int i = 0; i < bytes.length; i++) {
        result.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(result);
    } catch (e) {
      throw Exception('Failed to decrypt data');
    }
  }

  // Audit log helper
  static Map<String, dynamic> createAuditLog(
    String action,
    String userId,
    Map<String, dynamic>? metadata,
  ) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'action': action,
      'userId': userId,
      'ip': 'unknown', // Would be filled by backend
      'userAgent': 'mobile-app',
      'metadata': metadata ?? {},
    };
  }
}
