class CurrencyUtils {
  static const Map<String, Map<String, String>> currencies = {
    'USD': {
      'name': 'US Dollar',
      'symbol': '\$',
      'code': 'USD',
      'flag': '🇺🇸',
    },
    'TZS': {
      'name': 'Tanzanian Shilling',
      'symbol': 'TSh',
      'code': 'TZS',
      'flag': '🇹🇿',
    },
    'KES': {
      'name': 'Kenyan Shilling',
      'symbol': 'KSh',
      'code': 'KES',
      'flag': '🇰🇪',
    },
    'UGX': {
      'name': 'Ugandan Shilling',
      'symbol': 'USh',
      'code': 'UGX',
      'flag': '🇺🇬',
    },
    'RWF': {
      'name': 'Rwandan Franc',
      'symbol': 'RF',
      'code': 'RWF',
      'flag': '🇷🇼',
    },
    'EUR': {
      'name': 'Euro',
      'symbol': '€',
      'code': 'EUR',
      'flag': '🇪🇺',
    },
    'GBP': {
      'name': 'British Pound',
      'symbol': '£',
      'code': 'GBP',
      'flag': '🇬🇧',
    },
    'ZAR': {
      'name': 'South African Rand',
      'symbol': 'R',
      'code': 'ZAR',
      'flag': '🇿🇦',
    },
    'NGN': {
      'name': 'Nigerian Naira',
      'symbol': '₦',
      'code': 'NGN',
      'flag': '🇳🇬',
    },
    'GHS': {
      'name': 'Ghanaian Cedi',
      'symbol': '₵',
      'code': 'GHS',
      'flag': '🇬🇭',
    },
  };

  static String formatAmount(double amount, String currencyCode) {
    final currency = currencies[currencyCode];
    if (currency == null) return '$amount $currencyCode';
    
    final symbol = currency['symbol']!;
    
    // Format based on currency
    if (currencyCode == 'TZS' || currencyCode == 'UGX' || currencyCode == 'RWF') {
      // No decimals for currencies that don't use them commonly
      return '$symbol ${_formatNumber(amount.round())}';
    } else {
      // Two decimal places for other currencies
      return '$symbol ${_formatNumber(amount)}';
    }
  }
  
  static String _formatNumber(dynamic number) {
    if (number is int) {
      return _addCommas(number.toString());
    } else if (number is double) {
      if (number == number.roundToDouble()) {
        return _addCommas(number.round().toString());
      } else {
        return _addCommas(number.toStringAsFixed(2));
      }
    }
    return number.toString();
  }
  
  static String _addCommas(String number) {
    // Add commas for thousands separator
    if (number.contains('.')) {
      final parts = number.split('.');
      final wholePart = parts[0];
      final decimalPart = parts[1];
      return '${_addCommasToWholePart(wholePart)}.$decimalPart';
    } else {
      return _addCommasToWholePart(number);
    }
  }
  
  static String _addCommasToWholePart(String number) {
    String result = '';
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        result += ',';
      }
      result += number[i];
    }
    return result;
  }

  static List<String> getSupportedCurrencies() {
    return currencies.keys.toList();
  }
  
  static String getCurrencyName(String code) {
    return currencies[code]?['name'] ?? code;
  }
  
  static String getCurrencySymbol(String code) {
    return currencies[code]?['symbol'] ?? code;
  }
  
  static String getCurrencyFlag(String code) {
    return currencies[code]?['flag'] ?? '';
  }
  
  // Common exchange rates (in production, this would come from an API)
  static const Map<String, double> exchangeRates = {
    'USD': 1.0,
    'TZS': 2500.0,  // 1 USD = 2500 TZS (approximate)
    'KES': 150.0,   // 1 USD = 150 KES (approximate)
    'UGX': 3700.0,  // 1 USD = 3700 UGX (approximate)
    'RWF': 1250.0,  // 1 USD = 1250 RWF (approximate)
    'EUR': 0.92,    // 1 USD = 0.92 EUR (approximate)
    'GBP': 0.80,    // 1 USD = 0.80 GBP (approximate)
    'ZAR': 18.5,    // 1 USD = 18.5 ZAR (approximate)
    'NGN': 785.0,   // 1 USD = 785 NGN (approximate)
    'GHS': 12.0,    // 1 USD = 12 GHS (approximate)
  };
  
  static double convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final fromRate = exchangeRates[fromCurrency] ?? 1.0;
    final toRate = exchangeRates[toCurrency] ?? 1.0;
    
    // Convert to USD first, then to target currency
    final usdAmount = amount / fromRate;
    return usdAmount * toRate;
  }
  
  static String getDefaultCurrency() {
    // Default to TZS for Tanzanian Shilling
    return 'TZS';
  }

  // Quick helper method to format amounts in the default currency (TZS)
  static String formatKSH(double amount) {
    return formatAmount(amount, 'TZS');
  }

  // Helper to get the default currency's symbol
  static String getKSHSymbol() {
    return getCurrencySymbol('TZS'); // Returns 'TSh'
  }
}