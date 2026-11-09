import '../utils/constants.dart';

typedef CustomValidator = String? Function(String? value);

class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!RegExp(AppConstants.emailRegexPattern).hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }

    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return 'Password must contain at least one letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  // Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in most cases
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (!RegExp(AppConstants.phoneRegexPattern).hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Required field validation
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Name validation
  static String? name(String? value, [String? fieldName]) {
    final error = required(value, fieldName);
    if (error != null) return error;

    if (value!.trim().length < AppConstants.minNameLength) {
      return '${fieldName ?? 'Name'} must be at least ${AppConstants.minNameLength} characters long';
    }

    if (value.trim().length > AppConstants.maxNameLength) {
      return '${fieldName ?? 'Name'} cannot exceed ${AppConstants.maxNameLength} characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return '${fieldName ?? 'Name'} can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Amount validation
  static String? amount(String? value, {double? minAmount, double? maxAmount}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (minAmount != null && amount < minAmount) {
      return 'Amount must be at least ${minAmount.toStringAsFixed(2)}';
    }

    if (maxAmount != null && amount > maxAmount) {
      return 'Amount cannot exceed ${maxAmount.toStringAsFixed(2)}';
    }

    return null;
  }

  // URL validation
  static String? url(String? value, [bool required = false]) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }

    if (!RegExp(r'^https?:\/\/.+').hasMatch(value.trim())) {
      return 'Please enter a valid URL (must start with http:// or https://)';
    }

    return null;
  }

  // Date validation
  static String? date(String? value, [bool required = false]) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Date is required' : null;
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Registration number validation
  static String? registrationNumber(String? value) {
    final error = required(value, 'Registration number');
    if (error != null) return error;

    // Should be alphanumeric, 3-20 characters
    if (!RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch(value!)) {
      return 'Registration number must be 3-20 alphanumeric characters';
    }

    return null;
  }

  // Time validation
  static String? time(String? value, [bool required = false]) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Time is required' : null;
    }

    // Check HH:MM format
    if (!RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value.trim())) {
      return 'Please enter time in HH:MM format';
    }

    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? originalPassword) {
    final error = required(value, 'Password confirmation');
    if (error != null) return error;

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // File size validation
  static String? fileSize(int? sizeInBytes, {int? maxSizeInBytes}) {
    if (sizeInBytes == null) {
      return 'Invalid file size';
    }

    final maxSize = maxSizeInBytes ?? AppConstants.maxImageSize;

    if (sizeInBytes > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).toStringAsFixed(1);
      return 'File size must be less than ${maxSizeMB}MB';
    }

    return null;
  }

  // Description validation
  static String? description(String? value, [bool required = false]) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Description is required' : null;
    }

    if (value.trim().length > AppConstants.maxDescriptionLength) {
      return 'Description cannot exceed ${AppConstants.maxDescriptionLength} characters';
    }

    return null;
  }

  // Notes validation
  static String? notes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Notes are optional
    }

    if (value.trim().length > AppConstants.maxNotesLength) {
      return 'Notes cannot exceed ${AppConstants.maxNotesLength} characters';
    }

    return null;
  }

  // Compose multiple validators
  static String? compose(List<CustomValidator> validators, String? value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  // Age validation
  static String? age(String? value, {int? minAge, int? maxAge}) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < (minAge ?? 1)) {
      return 'Age must be at least ${minAge ?? 1}';
    }

    if (age > (maxAge ?? 120)) {
      return 'Age cannot exceed ${maxAge ?? 120}';
    }

    return null;
  }

  // Future date validation
  static String? futureDate(DateTime? value, [String? fieldName]) {
    if (value == null) {
      return '${fieldName ?? 'Date'} is required';
    }

    if (value.isBefore(DateTime.now())) {
      return '${fieldName ?? 'Date'} must be in the future';
    }

    return null;
  }

  // Past date validation
  static String? pastDate(DateTime? value, [String? fieldName]) {
    if (value == null) {
      return '${fieldName ?? 'Date'} is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '${fieldName ?? 'Date'} cannot be in the future';
    }

    return null;
  }

  // Date range validation
  static String? dateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Both start and end dates are required';
    }

    if (startDate.isAfter(endDate)) {
      return 'Start date must be before end date';
    }

    return null;
  }

  // Credit card number validation (basic)
  static String? creditCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Credit card number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length < 13 || cleaned.length > 19) {
      return 'Please enter a valid credit card number';
    }

    // Luhn algorithm check
    if (!_luhnCheck(cleaned)) {
      return 'Please enter a valid credit card number';
    }

    return null;
  }

  // Luhn algorithm for credit card validation
  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // Custom regex validation
  static String? regex(String? value, String pattern, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(pattern).hasMatch(value.trim())) {
      return errorMessage;
    }

    return null;
  }
}
