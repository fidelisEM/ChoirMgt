import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/models.dart';
import '../../utils/app_translations.dart';

class CreateSessionScreen extends StatefulWidget {

  const CreateSessionScreen({
    super.key,
    required this.choirId,
  });
  final String choirId;

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  final List<EventType> _eventTypes = EventType.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('attCreateSessionTitle')),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer2<AttendanceController, AuthController>(
          builder: (context, attendanceController, authController, child) {
            return FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('attSessionDetailsHeading'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          FormBuilderTextField(
                            name: 'title',
                            decoration: InputDecoration(
                              labelText: context.tr('attSessionTitleLabel'),
                              hintText: context.tr('attSessionTitleHint'),
                              prefixIcon: const Icon(Icons.title),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.minLength(3),
                            ]),
                          ),
                          const SizedBox(height: 16),

                          FormBuilderDropdown<EventType>(
                            name: 'eventType',
                            decoration: InputDecoration(
                              labelText: context.tr('attEventTypeLabel'),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            validator: FormBuilderValidators.required(),
                            items: _eventTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getEventTypeIcon(type),
                                      size: 20,
                                      color: _getEventTypeColor(type),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_getEventTypeLabel(type)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          
                          FormBuilderTextField(
                            name: 'description',
                            decoration: InputDecoration(
                              labelText: context.tr('attDescriptionOptionalLabel'),
                              hintText: context.tr('attDescriptionHint'),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('attScheduleHeading'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          FormBuilderDateTimePicker(
                            name: 'date',
                            inputType: InputType.date,
                            decoration: InputDecoration(
                              labelText: context.tr('date'),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            initialValue: DateTime.now(),
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 16),

                          FormBuilderDateTimePicker(
                            name: 'startTime',
                            inputType: InputType.time,
                            decoration: InputDecoration(
                              labelText: context.tr('attStartTimeLabel'),
                              prefixIcon: const Icon(Icons.access_time),
                            ),
                            initialValue: DateTime.now(),
                            validator: FormBuilderValidators.required(),
                          ),
                          const SizedBox(height: 16),

                          FormBuilderSlider(
                            name: 'graceMinutes',
                            decoration: InputDecoration(
                              labelText: context.tr('attGracePeriodLabel'),
                              helperText: context.tr('attGracePeriodHelper'),
                            ),
                            min: 5,
                            max: 60,
                            initialValue: 15,
                            divisions: 11,
                            valueWidget: (value) => Text('$value ${context.tr('attMinutesSuffix')}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              context.tr('attCreateSessionButton'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _createSession() async {
    if (!_formKey.currentState!.saveAndValidate()) return;

    final formData = _formKey.currentState!.value;
    final authController = Provider.of<AuthController>(context, listen: false);
    final attendanceController = Provider.of<AttendanceController>(context, listen: false);

    setState(() {
      _isLoading = true;
    });
    final trAttFailedCreateSession = context.tr('attFailedCreateSession'); // resolved before awaits
    final trAttSessionCreatedSuccess = context.tr('attSessionCreatedSuccess'); // resolved before awaits
    final trAttSuccessTitle = context.tr('attSuccessTitle'); // resolved before awaits
    final trAttUnexpectedErrorPrefix = context.tr('attUnexpectedErrorPrefix'); // resolved before awaits
    final trError = context.tr('error'); // resolved before awaits

    try {
      final date = formData['date'] as DateTime;
      final startTime = formData['startTime'] as DateTime;
      
      // Combine date and time
      final sessionDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );

      final success = await attendanceController.createAttendanceSession(
        choirId: widget.choirId,
        leaderId: authController.currentUser!.id,
        date: date,
        startTime: sessionDateTime,
        eventType: formData['eventType'] as EventType,
        title: formData['title'] as String,
        description: formData['description'] as String?,
        graceMinutes: (formData['graceMinutes'] as num).round(),
      );

      if (success) {
        Get.back();
        Get.snackbar(
          trAttSuccessTitle,
          trAttSessionCreatedSuccess,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          trError,
          attendanceController.errorMessage ?? trAttFailedCreateSession,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        trError,
        '$trAttUnexpectedErrorPrefix: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  IconData _getEventTypeIcon(EventType eventType) {
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

  Color _getEventTypeColor(EventType eventType) {
    switch (eventType) {
      case EventType.rehearsal:
        return Colors.blue;
      case EventType.service:
        return Colors.purple;
      case EventType.meeting:
        return Colors.orange;
      case EventType.other:
        return Colors.grey;
    }
  }

  String _getEventTypeLabel(EventType eventType) {
    switch (eventType) {
      case EventType.rehearsal:
        return context.tr('attEventRehearsal');
      case EventType.service:
        return context.tr('attEventService');
      case EventType.meeting:
        return context.tr('attEventMeeting');
      case EventType.other:
        return context.tr('attEventOther');
    }
  }
}