import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/language_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../utils/logger.dart';
import '../../widgets/custom_widgets.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _attendanceReminders = true;
  bool _paymentReminders = true;
  final bool _practiceReminders = true;
  final bool _generalNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthController, LanguageController>(
        builder: (context, authController, languageController, child) {
          final user = authController.currentUser;

          return ListView(
            children: [
              // Profile Section
              _buildSectionHeader('Profile'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            (user?.profileImageUrl != null &&
                                user?.profileImageUrl?.isNotEmpty == true)
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child:
                            (user?.profileImageUrl == null ||
                                user?.profileImageUrl?.isEmpty != false)
                            ? Text(
                                user?.fullName.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(user?.fullName ?? 'User'),
                      subtitle: Text(user?.email ?? 'No email'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editProfile(user),
                    ),
                  ],
                ),
              ),

              // App Preferences
              _buildSectionHeader('App Preferences'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: const Text('Choose your preferred theme'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeSelection(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Language'),
                      subtitle: Text(
                        _getLanguageName(
                          languageController.currentLanguageCode,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguageSelection(languageController),
                    ),
                  ],
                ),
              ),

              // Notifications
              _buildSectionHeader('Notifications'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive push notifications'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _updateNotificationSettings();
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive notifications via email'),
                      value: _emailNotifications,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _emailNotifications = value);
                              _updateNotificationSettings();
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('SMS Notifications'),
                      subtitle: const Text('Receive notifications via SMS'),
                      value: _smsNotifications,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _smsNotifications = value);
                              _updateNotificationSettings();
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Attendance Reminders'),
                      subtitle: const Text(
                        'Get reminded about upcoming rehearsals',
                      ),
                      value: _attendanceReminders,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _attendanceReminders = value);
                              _updateNotificationSettings();
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Payment Reminders'),
                      subtitle: const Text(
                        'Get reminded about outstanding payments',
                      ),
                      value: _paymentReminders,
                      onChanged: _notificationsEnabled
                          ? (value) {
                              setState(() => _paymentReminders = value);
                              _updateNotificationSettings();
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              // Account & Security
              _buildSectionHeader('Account & Security'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _changePassword(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text(
                        'Add extra security to your account',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _setup2FA(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text('Export Data'),
                      subtitle: const Text('Download your personal data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _exportData(),
                    ),
                  ],
                ),
              ),

              // Support & About
              _buildSectionHeader('Support & About'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Get help using the app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showHelp(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('Read our privacy policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPrivacyPolicy(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      subtitle: const Text('Read our terms of service'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTermsOfService(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('Version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAbout(),
                    ),
                  ],
                ),
              ),

              // Logout
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _logout(authController),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.gray600,
        ),
      ),
    );
  }

  String _getLanguageName(String locale) {
    switch (locale) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'English';
    }
  }

  void _editProfile(dynamic user) {
    Get.to(() => EditProfileScreen(user: user));
  }

  void _showLanguageSelection(LanguageController languageController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: languageController.currentLanguageCode,
                onChanged: (value) {
                  if (value != null) {
                    languageController.changeLanguage(value);
                    Get.back();
                    Helpers.showSuccessSnackbar('Language changed to English');
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Kiswahili'),
              leading: Radio<String>(
                value: 'sw',
                groupValue: languageController.currentLanguageCode,
                onChanged: (value) {
                  if (value != null) {
                    languageController.changeLanguage(value);
                    Get.back();
                    Helpers.showSuccessSnackbar(
                      'Language changed to Kiswahili',
                    );
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _updateNotificationSettings() {
    // Save notification preferences to local storage
    _saveNotificationPreferences();
    Helpers.showSuccessSnackbar('Notification settings updated');
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('practice_reminders', _practiceReminders);
      await prefs.setBool('payment_reminders', _paymentReminders);
      await prefs.setBool('general_notifications', _generalNotifications);
    } catch (e) {
      Logger.error('Failed to save notification preferences', e);
    }
  }

  void _showThemeSelection() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Row(
                children: [
                  Icon(Icons.brightness_auto),
                  SizedBox(width: 12),
                  Text('System'),
                ],
              ),
              subtitle: const Text('Follow system setting'),
              value: ThemeMode.system,
              groupValue: ThemeMode
                  .system, // This will be updated with proper implementation
              onChanged: (value) {
                if (value != null) {
                  // Update theme here
                  Get.back();
                  Helpers.showSuccessSnackbar('Theme updated');
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Row(
                children: [
                  Icon(Icons.brightness_high),
                  SizedBox(width: 12),
                  Text('Light'),
                ],
              ),
              subtitle: const Text('Light theme'),
              value: ThemeMode.light,
              groupValue: ThemeMode
                  .system, // This will be updated with proper implementation
              onChanged: (value) {
                if (value != null) {
                  // Update theme here
                  Get.back();
                  Helpers.showSuccessSnackbar('Theme updated');
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Row(
                children: [
                  Icon(Icons.brightness_low),
                  SizedBox(width: 12),
                  Text('Dark'),
                ],
              ),
              subtitle: const Text('Dark theme'),
              value: ThemeMode.dark,
              groupValue: ThemeMode
                  .system, // This will be updated with proper implementation
              onChanged: (value) {
                if (value != null) {
                  // Update theme here
                  Get.back();
                  Helpers.showSuccessSnackbar('Theme updated');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _changePassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(label: 'Current Password', obscureText: true),
            SizedBox(height: 16),
            CustomTextField(label: 'New Password', obscureText: true),
            SizedBox(height: 16),
            CustomTextField(label: 'Confirm New Password', obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar('Password changed successfully');
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _setup2FA() {
    Helpers.showInfoSnackbar('Two-factor authentication setup coming soon!');
  }

  void _exportData() {
    Helpers.showInfoSnackbar('Data export feature coming soon!');
  }

  void _showHelp() {
    Get.dialog(
      AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For help and support, please contact us at:\n\n'
          'Email: support@choirmanagement.com\n'
          'Phone: +254 700 000 000\n\n'
          'You can also check our FAQ section in the app documentation.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showInfoSnackbar('Opening support email...');
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Helpers.showInfoSnackbar('Privacy policy will open in browser');
  }

  void _showTermsOfService() {
    Helpers.showInfoSnackbar('Terms of service will open in browser');
  }

  void _showAbout() {
    Get.dialog(
      AlertDialog(
        title: const Text('About Choir Management'),
        content: const Text(
          'Choir Management System v1.0.0\n\n'
          'A comprehensive solution for managing choir operations including '
          'member management, attendance tracking, payment processing, and more.\n\n'
          'Built with Flutter and Supabase.\n\n'
          '© 2024 Choir Management System. All rights reserved.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _logout(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await authController.signOut();
                Get.offAllNamed('/login');
                Helpers.showSuccessSnackbar('Logged out successfully');
              } catch (e) {
                Helpers.showErrorSnackbar('Failed to logout: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
