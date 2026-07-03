class AppConstants {
  // App Information
  static const String appName = 'Choir Management System';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'A comprehensive choir management system for tracking members, attendance, and payments.';

  // Database Constants
  static const String usersTable = 'users';
  static const String choirsTable = 'choirs';
  static const String choirMembersTable = 'choir_members';
  static const String attendanceSessionsTable = 'attendance_sessions';
  static const String attendanceRecordsTable = 'attendance_records';
  static const String paymentsTable = 'payments';
  static const String notificationsTable = 'notifications';

  // Validation Constants
  static const int minNameLength = 2;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;
  static const int minPasswordLength = 6;

  // Default Values
  static const int defaultGraceMinutes = 15;
  static const double defaultAttendanceThreshold = 80.0;
  static const int defaultNotificationDays = 7;

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Currency
  static const String currency = 'KSH';
  static const String currencySymbol = 'KSH ';

  // File Extensions
  static const List<String> allowedImageExtensions = ['.jpg', '.jpeg', '.png'];
  static const List<String> allowedDocumentExtensions = ['.pdf', '.doc', '.docx'];
  static const List<String> allowedExportExtensions = ['.xlsx', '.pdf'];

  // Maximum File Sizes (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // QR Code
  static const int qrCodeSize = 200;
  static const int qrCodeErrorCorrectionLevel = 1; // Low to High: 0-3

  // Attendance
  static const int maxGraceMinutes = 60;
  static const int minGraceMinutes = 0;

  // Notifications
  static const int maxNotificationRetention = 90; // days

  // Colors (as hex strings for consistency across platforms)
  static const String primaryColorHex = '#2196F3';
  static const String successColorHex = '#4CAF50';
  static const String warningColorHex = '#FF9800';
  static const String errorColorHex = '#F44336';
  static const String infoColorHex = '#2196F3';

  // Status Colors
  static const String activeStatusColor = '#4CAF50';
  static const String inactiveStatusColor = '#FF9800';
  static const String suspendedStatusColor = '#F44336';

  // Payment Status Colors
  static const String completedPaymentColor = '#4CAF50';
  static const String pendingPaymentColor = '#FF9800';
  static const String overduePaymentColor = '#F44336';
  static const String cancelledPaymentColor = '#9E9E9E';

  // Attendance Status Colors
  static const String presentAttendanceColor = '#4CAF50';
  static const String lateAttendanceColor = '#FF9800';
  static const String absentAttendanceColor = '#F44336';

  // API Endpoints (if using external services)
  static const String notificationServiceUrl = '';
  static const String emailServiceUrl = '';
  static const String smsServiceUrl = '';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSmsNotifications = false;
  static const bool enableDataExport = true;
  static const bool enableDataImport = true;
  static const bool enableOfflineMode = false;

  // Cache Durations (in minutes)
  static const int shortCacheDuration = 5;
  static const int mediumCacheDuration = 30;
  static const int longCacheDuration = 60;

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;

  // Network Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String timeoutErrorMessage = 'Request timeout. Please try again.';
  static const String generalErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String permissionErrorMessage = 'You do not have permission to perform this action.';
  static const String notFoundErrorMessage = 'The requested resource was not found.';

  // Success Messages
  static const String createSuccessMessage = 'Created successfully!';
  static const String updateSuccessMessage = 'Updated successfully!';
  static const String deleteSuccessMessage = 'Deleted successfully!';
  static const String saveSuccessMessage = 'Saved successfully!';

  // Empty State Messages
  static const String noDataMessage = 'No data available';
  static const String noResultsMessage = 'No results found';
  static const String noPermissionMessage = 'No permission to view this content';

  // Loading Messages
  static const String loadingMessage = 'Loading...';
  static const String processingMessage = 'Processing...';
  static const String savingMessage = 'Saving...';
  static const String deletingMessage = 'Deleting...';

  // Confirmation Messages
  static const String deleteConfirmMessage = 'Are you sure you want to delete this item?';
  static const String unsavedChangesMessage = 'You have unsaved changes. Are you sure you want to leave?';
  static const String logoutConfirmMessage = 'Are you sure you want to log out?';

  // Help Text
  static const String passwordHelpText = 'Password must be at least $minPasswordLength characters long';
  static const String emailHelpText = 'Enter a valid email address';
  static const String phoneHelpText = 'Enter a valid phone number';
  static const String requiredFieldHelpText = 'This field is required';

  // Regex Patterns
  static const String emailRegexPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegexPattern = r'^\+?[0-9]{10,15}$';
  static const String nameRegexPattern = r'^[a-zA-Z\s]{2,}$';

  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String cacheKey = 'app_cache';
}