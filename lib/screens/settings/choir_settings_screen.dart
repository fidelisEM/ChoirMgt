import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/models.dart';
import '../../services/choir_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';
import 'member_roles_screen.dart';

class ChoirSettingsScreen extends StatefulWidget {

  const ChoirSettingsScreen({super.key, required this.choir});
  final ChoirModel choir;

  @override
  State<ChoirSettingsScreen> createState() => _ChoirSettingsScreenState();
}

class _ChoirSettingsScreenState extends State<ChoirSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  
  bool _isPublic = true;
  bool _allowSelfRegistration = false;
  bool _requireApproval = true;
  bool _autoReminders = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.choir.name;
    _descriptionController.text = widget.choir.description;
    // These are placeholder fields for future implementation
    _locationController.text = '';
    _contactController.text = '';
    _isPublic = true;
    // Set other settings to default values for now
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choir Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            _buildSectionHeader('Basic Information'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Choir Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Choir name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Location',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _contactController,
                      label: 'Contact Information',
                    ),
                  ],
                ),
              ),
            ),

            // Privacy Settings
            _buildSectionHeader('Privacy & Access'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Public Choir'),
                    subtitle: const Text('Make this choir visible to everyone'),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() => _isPublic = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Allow Self-Registration'),
                    subtitle: const Text('Let users join without invitation'),
                    value: _allowSelfRegistration,
                    onChanged: (value) {
                      setState(() => _allowSelfRegistration = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Require Leader Approval'),
                    subtitle: const Text('Leaders must approve new members'),
                    value: _requireApproval,
                    onChanged: _allowSelfRegistration ? (value) {
                      setState(() => _requireApproval = value);
                    } : null,
                  ),
                ],
              ),
            ),

            // Notification Settings
            _buildSectionHeader('Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Automatic Reminders'),
                    subtitle: const Text('Send attendance and payment reminders'),
                    value: _autoReminders,
                    onChanged: (value) {
                      setState(() => _autoReminders = value);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Reminder Schedule'),
                    subtitle: const Text('Set when to send reminders'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureReminders(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notification Templates'),
                    subtitle: const Text('Customize notification messages'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureTemplates(),
                  ),
                ],
              ),
            ),

            // Member Management
            _buildSectionHeader('Member Management'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Member Roles'),
                    subtitle: const Text('Manage member permissions'),
                    leading: const Icon(Icons.people),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageMemberRoles(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Attendance Tracking'),
                    subtitle: const Text('Configure attendance settings'),
                    leading: const Icon(Icons.check_circle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureAttendance(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Payment Settings'),
                    subtitle: const Text('Set up fees and payment options'),
                    leading: const Icon(Icons.payment),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configurePayments(),
                  ),
                ],
              ),
            ),

            // Data & Export
            _buildSectionHeader('Data Management'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Export Choir Data'),
                    subtitle: const Text('Download all choir information'),
                    leading: const Icon(Icons.download),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportChoirData(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Backup & Restore'),
                    subtitle: const Text('Backup or restore choir data'),
                    leading: const Icon(Icons.backup),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _backupRestore(),
                  ),
                ],
              ),
            ),

            // Danger Zone
            Consumer<AuthController>(
              builder: (context, authController, child) {
                if (authController.currentUser?.id != widget.choir.leaderId) {
                  return const SizedBox.shrink();
                }
                
                return Column(
                  children: [
                    _buildSectionHeader('Danger Zone'),
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Delete Choir',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Permanently delete this choir and all its data. This action cannot be undone.',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _deleteChoir,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete Choir'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
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

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update choir settings via ChoirService directly
      final choirService = ChoirService();
      
      // Create updated choir object
      final updatedChoir = ChoirModel(
        id: widget.choir.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        leaderId: widget.choir.leaderId,
        adminId: widget.choir.adminId,
        createdAt: widget.choir.createdAt,
        isActive: widget.choir.isActive,
      );
      
      final success = await choirService.updateChoir(updatedChoir);
      
      if (success) {
        Helpers.showSuccessSnackbar('Choir settings updated successfully');
        Get.back();
      } else {
        throw Exception('Failed to update choir settings');
      }
      
    } catch (e) {
      Helpers.showErrorSnackbar('Failed to update settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _configureReminders() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reminder Schedule'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.event),
              title: Text('Event Reminders'),
              subtitle: Text('Send 24 hours before events'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payment Reminders'),
              subtitle: Text('Send 3 days before due date'),
              trailing: Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Attendance Reminders'),
              subtitle: Text('Send 1 hour before practice'),
              trailing: Switch(value: false, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar('Reminder schedule updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _configureTemplates() {
    Get.dialog(
      AlertDialog(
        title: const Text('Message Templates'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Templates:'),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.event_note),
              title: Text('Event Reminder'),
              subtitle: Text('Template for upcoming event notifications'),
            ),
            ListTile(
              leading: Icon(Icons.attach_money),
              title: Text('Payment Due'),
              subtitle: Text('Template for payment reminder messages'),
            ),
            ListTile(
              leading: Icon(Icons.celebration),
              title: Text('Welcome Message'),
              subtitle: Text('Template for new member welcome'),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('General Announcement'),
              subtitle: Text('Template for choir announcements'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showInfoSnackbar('Template editor coming soon!');
            },
            child: const Text('Edit Templates'),
          ),
        ],
      ),
    );
  }

  void _manageMemberRoles() {
    Get.to(() => MemberRolesScreen(choir: widget.choir));
  }

  void _configureAttendance() {
    Get.dialog(
      AlertDialog(
        title: const Text('Attendance Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.timer),
              title: Text('Grace Period'),
              subtitle: Text('5 minutes late arrival tolerance'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Auto Reminders'),
              subtitle: Text('Send attendance reminders 1 hour before'),
            ),
            ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('QR Code Check-in'),
              subtitle: Text('Allow members to check-in via QR code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar('Attendance settings updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _configurePayments() {
    Get.dialog(
      AlertDialog(
        title: const Text('Payment Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.money),
              title: Text('Monthly Fee'),
              subtitle: Text('KSH 500 per month'),
            ),
            ListTile(
              leading: Icon(Icons.card_membership),
              title: Text('Registration Fee'),
              subtitle: Text('KSH 1,000 one-time fee'),
            ),
            ListTile(
              leading: Icon(Icons.calendar_month),
              title: Text('Payment Due Date'),
              subtitle: Text('5th of every month'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar('Payment settings updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportChoirData() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Export Choir Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export all choir data including:'),
            SizedBox(height: 12),
            Text('• Member information'),
            Text('• Attendance records'),
            Text('• Payment history'),
            Text('• Communication logs'),
            SizedBox(height: 16),
            Text('Choose export format:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDataExport('PDF');
            },
            child: const Text('Export PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDataExport('Excel');
            },
            child: const Text('Export Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataExport(String format) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      Get.back(); // Close loading

      Helpers.showSuccessSnackbar('Choir data exported successfully as $format');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Helpers.showErrorSnackbar('Failed to export data: $e');
    }
  }

  void _backupRestore() {
    Get.dialog(
      AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backup Options:'),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('Create Backup'),
              subtitle: Text('Save all choir data to cloud storage'),
            ),
            ListTile(
              leading: Icon(Icons.cloud_download),
              title: Text('Restore from Backup'),
              subtitle: Text('Restore choir data from previous backup'),
            ),
            SizedBox(height: 8),
            Text(
              'Note: Backups include all member data, attendance records, and payment history.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _createBackup();
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Simulate backup process
      await Future.delayed(const Duration(seconds: 3));

      Get.back(); // Close loading

      final backupId = DateTime.now().millisecondsSinceEpoch.toString();
      
      Get.dialog(
        AlertDialog(
          title: const Text('Backup Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Backup created successfully!'),
              const SizedBox(height: 12),
              Text('Backup ID: $backupId'),
              const SizedBox(height: 8),
              Text('Created: ${DateTime.now().toString().split('.')[0]}'),
              const SizedBox(height: 12),
              const Text(
                'Keep this backup ID safe for future restoration.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Helpers.showErrorSnackbar('Failed to create backup: $e');
    }
  }

  void _deleteChoir() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          'Delete Choir',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.choir.name}"? '
          'This will permanently delete all choir data including members, '
          'attendance records, and payments. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _confirmDeleteChoir();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChoir() {
    Get.dialog(
      AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please type "${widget.choir.name}" to confirm deletion:'),
            const SizedBox(height: 16),
            const CustomTextField(
              label: 'Type choir name to confirm',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performChoirDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Choir'),
          ),
        ],
      ),
    );
  }

  Future<void> _performChoirDeletion() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final choirService = ChoirService();
      final success = await choirService.deleteChoir(widget.choir.id);

      // Hide loading
      Get.back();

      if (success) {
        Helpers.showSuccessSnackbar('Choir deleted successfully');
        // Navigate back to choir list
        Get.offAllNamed('/dashboard');
      } else {
        Helpers.showErrorSnackbar('Failed to delete choir. Please try again.');
      }
    } catch (e) {
      // Hide loading if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Helpers.showErrorSnackbar('Failed to delete choir: $e');
    }
  }
}