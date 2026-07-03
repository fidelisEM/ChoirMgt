import 'package:choir_management_system/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@tld'), isNotNull);
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('member@choir.org'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects passwords shorter than the minimum length', () {
      expect(Validators.password('a1'), isNotNull);
    });

    test('rejects passwords with no letter', () {
      expect(Validators.password('12345678'), isNotNull);
    });

    test('rejects passwords with no digit', () {
      expect(Validators.password('abcdefgh'), isNotNull);
    });

    test('accepts a password with letters and digits', () {
      expect(Validators.password('abc12345'), isNull);
    });
  });

  group('Validators.phoneNumber', () {
    test('is optional - null/empty passes', () {
      expect(Validators.phoneNumber(null), isNull);
      expect(Validators.phoneNumber(''), isNull);
    });

    test('rejects obviously invalid numbers', () {
      expect(Validators.phoneNumber('abc'), isNotNull);
    });

    test('accepts a plausible international number', () {
      expect(Validators.phoneNumber('+254712345678'), isNull);
    });
  });

  group('Validators.amount', () {
    test('rejects non-numeric input', () {
      expect(Validators.amount('not-a-number'), isNotNull);
    });

    test('rejects zero and negative amounts', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
    });

    test('enforces min/max bounds when provided', () {
      expect(Validators.amount('5', minAmount: 10), isNotNull);
      expect(Validators.amount('500', maxAmount: 100), isNotNull);
      expect(Validators.amount('50', minAmount: 10, maxAmount: 100), isNull);
    });
  });

  group('Validators.url', () {
    test('is optional unless required is true', () {
      expect(Validators.url(''), isNull);
      expect(Validators.url('', true), isNotNull);
    });

    test('requires an http(s) scheme', () {
      expect(Validators.url('ftp://example.com'), isNotNull);
      expect(Validators.url('https://example.com'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('flags a mismatch', () {
      expect(Validators.confirmPassword('abc123', 'abc124'), isNotNull);
    });

    test('passes on an exact match', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('Validators.creditCard (Luhn check)', () {
    test('accepts a known-valid test number', () {
      expect(Validators.creditCard('4242424242424242'), isNull);
    });

    test('rejects a number that fails the Luhn checksum', () {
      expect(Validators.creditCard('4242424242424241'), isNotNull);
    });

    test('rejects an implausible length', () {
      expect(Validators.creditCard('1234'), isNotNull);
    });
  });

  group('Validators.compose', () {
    test('returns the first failing validator\'s message', () {
      final result = Validators.compose([
        (v) => Validators.required(v, 'Name'),
        (v) => Validators.name(v, 'Name'),
      ], '');

      expect(result, isNotNull);
    });

    test('returns null when all validators pass', () {
      final result = Validators.compose([
        (v) => Validators.required(v, 'Name'),
        (v) => Validators.name(v, 'Name'),
      ], 'Jane Doe');

      expect(result, isNull);
    });
  });
}
