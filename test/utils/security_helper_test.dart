import 'package:choir_management_system/utils/security_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityHelper.sanitizeInput', () {
    test('escapes HTML-significant characters to prevent XSS', () {
      const malicious = '<script>alert("xss")</script>';
      final sanitized = SecurityHelper.sanitizeInput(malicious);

      expect(sanitized, isNot(contains('<script>')));
      expect(sanitized, contains('&lt;script&gt;'));
    });

    test('leaves plain text untouched', () {
      expect(SecurityHelper.sanitizeInput('Jane Doe'), 'Jane Doe');
    });
  });

  group('SecurityHelper.containsSQLInjection', () {
    test('flags common SQL injection patterns', () {
      expect(SecurityHelper.containsSQLInjection("' OR 1=1 --"), isTrue);
      expect(SecurityHelper.containsSQLInjection('DROP TABLE users'), isTrue);
    });

    test('does not flag ordinary text', () {
      expect(SecurityHelper.containsSQLInjection('Jane Doe'), isFalse);
      expect(SecurityHelper.containsSQLInjection('choir practice at 6pm'), isFalse);
    });
  });

  group('SecurityHelper.isValidEmailFormat', () {
    test('accepts a well-formed email with no injection content', () {
      expect(SecurityHelper.isValidEmailFormat('member@choir.org'), isTrue);
    });

    test('rejects malformed emails', () {
      expect(SecurityHelper.isValidEmailFormat('not-an-email'), isFalse);
    });

    test('rejects an email-shaped string carrying an injection payload', () {
      expect(SecurityHelper.isValidEmailFormat("a'--@choir.org"), isFalse);
    });
  });

  group('SecurityHelper.hasPermission', () {
    test('super_admin has every admin permission', () {
      for (final permission in ['manage_users', 'manage_payments', 'delete']) {
        expect(SecurityHelper.hasPermission('super_admin', permission), isTrue);
      }
    });

    test('leader can manage payments and attendance but not users', () {
      expect(SecurityHelper.hasPermission('leader', 'manage_payments'), isTrue);
      expect(SecurityHelper.hasPermission('leader', 'manage_attendance'), isTrue);
      expect(SecurityHelper.hasPermission('leader', 'manage_users'), isFalse);
      expect(SecurityHelper.hasPermission('leader', 'delete'), isFalse);
    });

    test('admin has the broadest permission set', () {
      expect(SecurityHelper.hasPermission('admin', 'manage_users'), isTrue);
      expect(SecurityHelper.hasPermission('admin', 'delete'), isTrue);
    });

    test('member is read-only', () {
      expect(SecurityHelper.hasPermission('member', 'read'), isTrue);
      expect(SecurityHelper.hasPermission('member', 'write'), isFalse);
      expect(SecurityHelper.hasPermission('member', 'manage_users'), isFalse);
    });

    test('guest has no permissions and unknown roles default to none', () {
      expect(SecurityHelper.hasPermission('guest', 'read'), isFalse);
      expect(SecurityHelper.hasPermission('nonexistent-role', 'read'), isFalse);
    });
  });

  group('SecurityHelper.isValidURL', () {
    test('rejects non-http(s) schemes', () {
      expect(SecurityHelper.isValidURL('javascript:alert(1)'), isFalse);
      expect(SecurityHelper.isValidURL('file:///etc/passwd'), isFalse);
    });

    test('accepts a plain https URL', () {
      expect(SecurityHelper.isValidURL('https://example.com'), isTrue);
    });
  });

  group('SecurityHelper.isPasswordSecure', () {
    test('rejects short passwords regardless of complexity', () {
      expect(SecurityHelper.isPasswordSecure('Ab1!'), isFalse);
    });

    test('rejects passwords with fewer than 3 of the 4 character classes', () {
      expect(SecurityHelper.isPasswordSecure('alllowercase'), isFalse);
    });

    test('accepts a password meeting length + 3-class complexity', () {
      expect(SecurityHelper.isPasswordSecure('Abcdefg1'), isTrue);
    });
  });

  group('SecurityHelper.maskSensitiveData', () {
    test('masks the middle, keeping visibleChars at each end', () {
      final masked = SecurityHelper.maskSensitiveData('1234567890', visibleChars: 2);
      expect(masked, '12******90');
    });

    test('fully masks strings too short to safely reveal either end', () {
      final masked = SecurityHelper.maskSensitiveData('1234', visibleChars: 4);
      expect(masked, '****');
    });
  });
}
