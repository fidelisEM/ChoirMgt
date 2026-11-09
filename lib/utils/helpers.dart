import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/models.dart';
import 'constants.dart';

class Helpers {
  // Date formatting
  static String formatDate(DateTime date, {String? pattern}) {
    return DateFormat(pattern ?? AppConstants.dateFormat).format(date);
  }

  static String formatTime(DateTime time, {String? pattern}) {
    return DateFormat(pattern ?? AppConstants.timeFormat).format(time);
  }

  static String formatDateTime(DateTime dateTime, {String? pattern}) {
    return DateFormat(pattern ?? AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays == -1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 0 && difference.inDays >= -7) {
      return 'In ${-difference.inDays} days';
    } else {
      return formatDate(date);
    }
  }

  // Currency formatting
  static String formatCurrency(double amount, {String? currency}) {
    final formatter = NumberFormat.currency(
      symbol: currency ?? AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatNumber(num number, {int? decimalDigits}) {
    final formatter = NumberFormat();
    if (decimalDigits != null) {
      formatter.minimumFractionDigits = decimalDigits;
      formatter.maximumFractionDigits = decimalDigits;
    }
    return formatter.format(number);
  }

  // Percentage formatting
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Color helpers
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Color getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.refunded:
        return Colors.blue;
      case PaymentStatus.failed:
        return Colors.red;
    }
  }

  static Color getAttendanceStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
    }
  }

  // Icon helpers
  static IconData getEventTypeIcon(EventType eventType) {
    switch (eventType) {
      case EventType.rehearsal:
        return Icons.music_note;
      case EventType.service:
        return Icons.church;
      case EventType.meeting:
        return Icons.meeting_room;
      case EventType.other:
        return Icons.event;
    }
  }

  static IconData getPaymentTypeIcon(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.registration:
        return Icons.person_add;
      case PaymentType.monthly:
        return Icons.calendar_today;
      case PaymentType.quarterly:
        return Icons.calendar_view_month;
      case PaymentType.annual:
        return Icons.date_range;
      case PaymentType.special:
        return Icons.star;
      case PaymentType.other:
        return Icons.payment;
    }
  }

  // Validation helpers
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(AppConstants.emailRegexPattern).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone number is optional in most cases
    }
    if (!RegExp(AppConstants.phoneRegexPattern).hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? validateName(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Name'} is required';
    }
    if (value.trim().length < AppConstants.minNameLength) {
      return '${fieldName ?? 'Name'} must be at least ${AppConstants.minNameLength} characters';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return '${fieldName ?? 'Name'} cannot exceed ${AppConstants.maxNameLength} characters';
    }
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    return null;
  }

  // QR Code helpers
  static Widget generateQRCode(
    String data, {
    double size = 200,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(color: foregroundColor),
      dataModuleStyle: QrDataModuleStyle(color: foregroundColor),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  static String generateMemberQRData(
    String registrationNumber,
    String choirId,
  ) {
    return '$registrationNumber|$choirId|${DateTime.now().millisecondsSinceEpoch}';
  }

  // Text helpers
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static String truncateText(
    String text,
    int maxLength, {
    String suffix = '...',
  }) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$suffix';
  }

  static String getInitials(String name, {int maxLength = 2}) {
    if (name.isEmpty) return '';
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .take(maxLength)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();
    return initials;
  }

  // List helpers
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static Map<K, List<V>> groupBy<K, V>(
    List<V> list,
    K Function(V) keyFunction,
  ) {
    final Map<K, List<V>> result = {};
    for (final item in list) {
      final key = keyFunction(item);
      if (result.containsKey(key)) {
        result[key]!.add(item);
      } else {
        result[key] = [item];
      }
    }
    return result;
  }

  // Analytics helpers
  static double calculateAttendanceRate(int present, int total) {
    if (total == 0) return 0.0;
    return (present / total) * 100;
  }

  static double calculateCollectionRate(double collected, double expected) {
    if (expected == 0) return 0.0;
    return (collected / expected) * 100;
  }

  // Snackbar helpers
  static void showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  static void showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  static void showWarningSnackbar(String message) {
    Get.snackbar(
      'Warning',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfoSnackbar(String message) {
    Get.snackbar(
      'Info',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  // Dialog helpers
  static Future<bool> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Error handling
  static String getErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return AppConstants.generalErrorMessage;
    }
  }

  // Device helpers
  static bool isTablet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide >= 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Theme helpers
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // File size helpers
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final int i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // Random helpers
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(
        length,
        (index) => chars.codeUnitAt((random + index) % chars.length),
      ),
    );
  }
}

// Extension methods for convenience
extension StringExtension on String {
  String get capitalize => Helpers.capitalize(this);
  String get capitalizeWords => Helpers.capitalizeWords(this);
  String truncate(int maxLength, {String suffix = '...'}) =>
      Helpers.truncateText(this, maxLength, suffix: suffix);
}

extension DateTimeExtension on DateTime {
  String get formatDate => Helpers.formatDate(this);
  String get formatTime => Helpers.formatTime(this);
  String get formatDateTime => Helpers.formatDateTime(this);
  String get formatRelative => Helpers.formatRelativeDate(this);
}

extension DoubleExtension on double {
  String get formatCurrency => Helpers.formatCurrency(this);
  String get formatPercentage => Helpers.formatPercentage(this);
}
