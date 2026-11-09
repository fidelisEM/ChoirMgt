import 'package:choir_management_system/utils/currency_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyUtils.formatAmount', () {
    test('formats zero-decimal currencies (TZS/UGX/RWF) without decimals', () {
      expect(CurrencyUtils.formatAmount(1500, 'TZS'), 'TSh 1,500');
    });

    test(
      'formats other currencies with two decimal places when fractional',
      () {
        expect(CurrencyUtils.formatAmount(1234.5, 'USD'), '\$ 1,234.50');
      },
    );

    test('drops decimals for a whole-number amount in a decimal currency', () {
      expect(CurrencyUtils.formatAmount(1000, 'USD'), '\$ 1,000');
    });

    test('falls back to "<amount> <code>" for an unknown currency', () {
      expect(CurrencyUtils.formatAmount(10, 'XXX'), '10.0 XXX');
    });
  });

  group('CurrencyUtils currency lookups', () {
    test('getCurrencySymbol returns the known symbol', () {
      expect(CurrencyUtils.getCurrencySymbol('KES'), 'KSh');
    });

    test('getCurrencySymbol falls back to the code itself when unknown', () {
      expect(CurrencyUtils.getCurrencySymbol('ZZZ'), 'ZZZ');
    });

    test('getDefaultCurrency is TZS', () {
      expect(CurrencyUtils.getDefaultCurrency(), 'TZS');
    });

    test('getSupportedCurrencies includes all documented currencies', () {
      final supported = CurrencyUtils.getSupportedCurrencies();
      expect(
        supported,
        containsAll([
          'USD',
          'TZS',
          'KES',
          'UGX',
          'RWF',
          'EUR',
          'GBP',
          'ZAR',
          'NGN',
          'GHS',
        ]),
      );
    });
  });

  group('CurrencyUtils.convertCurrency', () {
    test('returns the same amount for a same-currency conversion', () {
      expect(CurrencyUtils.convertCurrency(100, 'USD', 'USD'), 100);
    });

    test('converts USD to KES using the documented exchange rate', () {
      expect(CurrencyUtils.convertCurrency(1, 'USD', 'KES'), 150.0);
    });

    test('round-trips back to (approximately) the original amount', () {
      final converted = CurrencyUtils.convertCurrency(100, 'USD', 'TZS');
      final roundTripped = CurrencyUtils.convertCurrency(
        converted,
        'TZS',
        'USD',
      );
      expect(roundTripped, closeTo(100, 0.0001));
    });
  });
}
