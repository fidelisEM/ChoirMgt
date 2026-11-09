class ValidationResult {
  ValidationResult._({required this.isValid, this.error});

  factory ValidationResult.valid() => ValidationResult._(isValid: true);
  factory ValidationResult.invalid(String error) =>
      ValidationResult._(isValid: false, error: error);
  final bool isValid;
  final String? error;
}

class ValidationService {
  factory ValidationService() => _instance;
  ValidationService._internal();
  static final ValidationService _instance = ValidationService._internal();

  // Email validation
  ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return ValidationResult.invalid('Please enter a valid email address');
    }

    return ValidationResult.valid();
  }

  // Phone number validation
  ValidationResult validatePhoneNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.invalid('Phone number is required');
    }

    // Remove spaces, hyphens, parentheses
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits and optional + at start
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return ValidationResult.invalid(
        'Please enter a valid phone number (10-15 digits)',
      );
    }

    return ValidationResult.valid();
  }

  // Name validation
  ValidationResult validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }

    if (name.trim().length < 2) {
      return ValidationResult.invalid(
        '$fieldName must be at least 2 characters long',
      );
    }

    if (name.trim().length > 50) {
      return ValidationResult.invalid(
        '$fieldName must be less than 50 characters',
      );
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(name.trim())) {
      return ValidationResult.invalid('$fieldName contains invalid characters');
    }

    return ValidationResult.valid();
  }

  // Password validation
  ValidationResult validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ValidationResult.invalid('Password is required');
    }

    if (password.length < 8) {
      return ValidationResult.invalid(
        'Password must be at least 8 characters long',
      );
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password)) {
      return ValidationResult.invalid(
        'Password must contain at least one uppercase letter, one lowercase letter, and one number',
      );
    }

    return ValidationResult.valid();
  }

  // Registration number validation
  ValidationResult validateRegistrationNumber(String? regNumber) {
    if (regNumber == null || regNumber.trim().isEmpty) {
      return ValidationResult.invalid('Registration number is required');
    }

    // Allow alphanumeric characters, hyphens, and underscores
    final regNumberRegex = RegExp(r'^[a-zA-Z0-9\-_]+$');
    if (!regNumberRegex.hasMatch(regNumber.trim())) {
      return ValidationResult.invalid(
        'Registration number can only contain letters, numbers, hyphens, and underscores',
      );
    }

    if (regNumber.trim().length < 3 || regNumber.trim().length > 20) {
      return ValidationResult.invalid(
        'Registration number must be between 3 and 20 characters',
      );
    }

    return ValidationResult.valid();
  }

  // Amount validation
  ValidationResult validateAmount(
    String? amount, {
    String fieldName = 'Amount',
  }) {
    if (amount == null || amount.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }

    final double? parsedAmount = double.tryParse(amount.trim());
    if (parsedAmount == null) {
      return ValidationResult.invalid('Please enter a valid $fieldName');
    }

    if (parsedAmount < 0) {
      return ValidationResult.invalid('$fieldName cannot be negative');
    }

    if (parsedAmount > 999999.99) {
      return ValidationResult.invalid('$fieldName cannot exceed 999,999.99');
    }

    return ValidationResult.valid();
  }

  // Date validation
  ValidationResult validateDate(DateTime? date, {String fieldName = 'Date'}) {
    if (date == null) {
      return ValidationResult.invalid('$fieldName is required');
    }

    final now = DateTime.now();
    final maxDate = DateTime(now.year + 1, now.month, now.day);
    final minDate = DateTime(now.year - 10, now.month, now.day);

    if (date.isAfter(maxDate)) {
      return ValidationResult.invalid(
        '$fieldName cannot be more than 1 year in the future',
      );
    }

    if (date.isBefore(minDate)) {
      return ValidationResult.invalid(
        '$fieldName cannot be more than 10 years in the past',
      );
    }

    return ValidationResult.valid();
  }

  // Choir name validation
  ValidationResult validateChoirName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('Choir name is required');
    }

    if (name.trim().length < 3) {
      return ValidationResult.invalid(
        'Choir name must be at least 3 characters long',
      );
    }

    if (name.trim().length > 100) {
      return ValidationResult.invalid(
        'Choir name must be less than 100 characters',
      );
    }

    return ValidationResult.valid();
  }

  // Event title validation
  ValidationResult validateEventTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ValidationResult.invalid('Event title is required');
    }

    if (title.trim().length < 3) {
      return ValidationResult.invalid(
        'Event title must be at least 3 characters long',
      );
    }

    if (title.trim().length > 200) {
      return ValidationResult.invalid(
        'Event title must be less than 200 characters',
      );
    }

    return ValidationResult.valid();
  }

  // Multiple field validation
  List<String> validateMultipleFields(
    Map<String, ValidationResult> validations,
  ) {
    final errors = <String>[];

    validations.forEach((field, result) {
      if (!result.isValid && result.error != null) {
        errors.add(result.error!);
      }
    });

    return errors;
  }

  // Clean and format input
  String cleanInput(String? input) {
    if (input == null) return '';
    return input.trim();
  }

  String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone; // Return original if can't format
  }

  // Sanitize input for database
  String sanitizeForDatabase(String input) {
    return input.trim().replaceAll(RegExp(r'[<>"%;()&+]'), '');
  }
}

// Extension for form field validation
extension FormFieldValidation on String? {
  ValidationResult get isValidEmail => ValidationService().validateEmail(this);
  ValidationResult get isValidPhone =>
      ValidationService().validatePhoneNumber(this);
  ValidationResult get isValidName => ValidationService().validateName(this);
  ValidationResult get isValidPassword =>
      ValidationService().validatePassword(this);
}
