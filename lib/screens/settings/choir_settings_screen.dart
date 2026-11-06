import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/report_controller.dart';
import '../../models/models.dart';
import '../../services/choir_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
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
        title: Text(context.tr('settingsChoirSettings')),
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
                : Text(
                    context.tr('save'),
                    style: const TextStyle(color: Colors.white),
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
            _buildSectionHeader(context.tr('settingsBasicInformation')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: context.tr('settingsChoirName'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('settingsChoirNameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: context.tr('description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      label: context.tr('settingsLocation'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _contactController,
                      label: context.tr('settingsContactInformation'),
                    ),
                  ],
                ),
              ),
            ),

            // Privacy Settings
            _buildSectionHeader(context.tr('settingsPrivacyAccess')),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.tr('settingsPublicChoir')),
                    subtitle: Text(context.tr('settingsPublicChoirDesc')),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() => _isPublic = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(context.tr('settingsAllowSelfRegistration')),
                    subtitle: Text(context.tr('settingsAllowSelfRegistrationDesc')),
                    value: _allowSelfRegistration,
                    onChanged: (value) {
                      setState(() => _allowSelfRegistration = value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(context.tr('settingsRequireLeaderApproval')),
                    subtitle: Text(context.tr('settingsRequireLeaderApprovalDesc')),
                    value: _requireApproval,
                    onChanged: _allowSelfRegistration ? (value) {
                      setState(() => _requireApproval = value);
                    } : null,
                  ),
                ],
              ),
            ),

            // Notification Settings
            _buildSectionHeader(context.tr('settingsNotifications')),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.tr('settingsAutomaticReminders')),
                    subtitle: Text(context.tr('settingsAutomaticRemindersDesc')),
                    value: _autoReminders,
                    onChanged: (value) {
                      setState(() => _autoReminders = value);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(context.tr('settingsReminderSchedule')),
                    subtitle: Text(context.tr('settingsReminderScheduleDesc')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureReminders(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(context.tr('settingsNotificationTemplates')),
                    subtitle: Text(context.tr('settingsNotificationTemplatesDesc')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureTemplates(),
                  ),
                ],
              ),
            ),

            // Member Management
            _buildSectionHeader(context.tr('settingsMemberManagement')),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(context.tr('settingsMemberRoles')),
                    subtitle: Text(context.tr('settingsMemberRolesDesc')),
                    leading: const Icon(Icons.people),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageMemberRoles(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(context.tr('settingsAttendanceTracking')),
                    subtitle: Text(context.tr('settingsAttendanceTrackingDesc')),
                    leading: const Icon(Icons.check_circle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configureAttendance(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(context.tr('settingsPaymentSettings')),
                    subtitle: Text(context.tr('settingsPaymentSettingsDesc')),
                    leading: const Icon(Icons.payment),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _configurePayments(),
                  ),
                ],
              ),
            ),

            // Data & Export
            _buildSectionHeader(context.tr('settingsDataManagement')),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(context.tr('settingsExportChoirData')),
                    subtitle: Text(context.tr('settingsExportChoirDataDesc')),
                    leading: const Icon(Icons.download),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportChoirData(),
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
                    _buildSectionHeader(context.tr('settingsDangerZone')),
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('settingsDeleteChoir'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.tr('settingsDeleteChoirWarning'),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _deleteChoir,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(context.tr('settingsDeleteChoir')),
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
      if (!mounted) return;

      if (success) {
        final updatedMessage = context.tr('settingsChoirSettingsUpdated');
        Get.back(); // pop before the snackbar, which is itself a route
        Helpers.showSuccessSnackbar(updatedMessage);
      } else {
        throw Exception('Failed to update choir settings');
      }

    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar('${context.tr('settingsUpdateSettingsFailed')}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _configureReminders() {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('settingsReminderSchedule')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(context.tr('settingsEventReminders')),
              subtitle: Text(context.tr('settingsEventRemindersDesc')),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: Text(context.tr('settingsPaymentReminders')),
              subtitle: Text(context.tr('settingsPaymentRemindersDueDesc')),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text(context.tr('settingsAttendanceReminders')),
              subtitle: Text(context.tr('settingsAttendanceRemindersPracticeDesc')),
              trailing: const Switch(value: false, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar(context.tr('settingsReminderScheduleUpdated'));
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _configureTemplates() {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('settingsMessageTemplates')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('settingsAvailableTemplates')),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.event_note),
              title: Text(context.tr('settingsTemplateEventReminder')),
              subtitle: Text(context.tr('settingsTemplateEventReminderDesc')),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(context.tr('settingsTemplatePaymentDue')),
              subtitle: Text(context.tr('settingsTemplatePaymentDueDesc')),
            ),
            ListTile(
              leading: const Icon(Icons.celebration),
              title: Text(context.tr('settingsTemplateWelcomeMessage')),
              subtitle: Text(context.tr('settingsTemplateWelcomeMessageDesc')),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(context.tr('settingsTemplateGeneralAnnouncement')),
              subtitle: Text(context.tr('settingsTemplateGeneralAnnouncementDesc')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showInfoSnackbar(context.tr('settingsTemplateEditorComingSoon'));
            },
            child: Text(context.tr('settingsEditTemplates')),
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
        title: Text(context.tr('settingsAttendanceSettings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer),
              title: Text(context.tr('settingsGracePeriod')),
              subtitle: Text(context.tr('settingsGracePeriodDesc')),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(context.tr('settingsAutoReminders')),
              subtitle: Text(context.tr('settingsAutoRemindersDesc')),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(context.tr('settingsQrCodeCheckIn')),
              subtitle: Text(context.tr('settingsQrCodeCheckInDesc')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar(context.tr('settingsAttendanceSettingsUpdated'));
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _configurePayments() {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('settingsPaymentSettings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money),
              title: Text(context.tr('settingsMonthlyFee')),
              subtitle: Text('KSH 500 ${context.tr('settingsPerMonth')}'),
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: Text(context.tr('settingsRegistrationFee')),
              subtitle: Text('KSH 1,000 ${context.tr('settingsOneTimeFee')}'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(context.tr('settingsPaymentDueDate')),
              subtitle: Text(context.tr('settingsPaymentDueDateDesc')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Helpers.showSuccessSnackbar(context.tr('settingsPaymentSettingsUpdated'));
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _exportChoirData() async {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('settingsExportChoirData')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('settingsExportIncludes')),
            const SizedBox(height: 12),
            Text('• ${context.tr('settingsExportMemberInfo')}'),
            Text('• ${context.tr('settingsExportAttendanceRecords')}'),
            Text('• ${context.tr('settingsExportPaymentHistory')}'),
            const SizedBox(height: 16),
            Text(context.tr('settingsChooseExportFormat')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDataExport('PDF');
            },
            child: Text(context.tr('settingsExportPdf')),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performDataExport('Excel');
            },
            child: Text(context.tr('settingsExportExcel')),
          ),
        ],
      ),
    );
  }

  Future<void> _performDataExport(String format) async {
    final reportController = Provider.of<ReportController>(context, listen: false);
    final choirId = widget.choir.id;
    final exportedMsg = context.tr('settingsChoirDataExported');
    final noDataMsg = context.tr('choirNoDataForExportMessage');
    final failedMsg = context.tr('settingsExportDataFailed');

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Same overview report and export path as the choir page's Export action.
      await reportController.generateChoirOverviewReport(
        choirId: choirId,
        fromDate: DateTime.now().subtract(const Duration(days: 180)),
        toDate: DateTime.now(),
      );

      if (!reportController.hasReportData) {
        if (Get.isDialogOpen ?? false) Get.back();
        Helpers.showErrorSnackbar(noDataMsg);
        return;
      }

      final reportData = reportController.currentReport;
      final exportService = ExportService();
      final filePath = format == 'PDF'
          ? await exportService.exportMembershipToPDF(reportData)
          : await exportService.exportMembershipToExcel(reportData);

      if (Get.isDialogOpen ?? false) Get.back();

      if (filePath != null) {
        Helpers.showSuccessSnackbar('$exportedMsg $format: $filePath');
      } else {
        Helpers.showErrorSnackbar(failedMsg);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Helpers.showErrorSnackbar('$failedMsg: $e');
    }
  }

  void _deleteChoir() {
    Get.dialog(
      AlertDialog(
        title: Text(
          context.tr('settingsDeleteChoir'),
          style: const TextStyle(color: Colors.red),
        ),
        content: Text(
          '${context.tr('settingsDeleteChoirConfirm')} "${widget.choir.name}"? '
          '${context.tr('settingsDeleteChoirWarningDetailed')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('cancel')),
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
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChoir() {
    Get.dialog(
      AlertDialog(
        title: Text(context.tr('settingsFinalConfirmation')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.tr('settingsTypeToConfirmDeletion')} "${widget.choir.name}" ${context.tr('settingsToConfirmDeletionSuffix')}'),
            const SizedBox(height: 16),
            CustomTextField(
              label: context.tr('settingsTypeChoirNameToConfirm'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.tr('cancel')),
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
            child: Text(context.tr('settingsDeleteChoir')),
          ),
        ],
      ),
    );
  }

  Future<void> _performChoirDeletion() async {
    // Resolved before any await: the choir is gone either way, so navigation
    // must not depend on this screen still being mounted.
    final deletedMsg = context.tr('settingsChoirDeletedSuccess');
    final deleteRetryMsg = context.tr('settingsChoirDeleteFailedRetry');
    final deleteFailedMsg = context.tr('settingsChoirDeleteFailed');

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
        Helpers.showSuccessSnackbar(deletedMsg);
        // Navigate back to choir list
        Get.offAllNamed('/dashboard');
      } else {
        Helpers.showErrorSnackbar(deleteRetryMsg);
      }
    } catch (e) {
      // Hide loading if still showing
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Helpers.showErrorSnackbar('$deleteFailedMsg: $e');
    }
  }
}