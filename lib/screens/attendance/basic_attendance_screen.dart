import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../widgets/custom_widgets.dart';

class BasicAttendanceScreen extends StatefulWidget {
  const BasicAttendanceScreen({super.key});

  @override
  State<BasicAttendanceScreen> createState() => _BasicAttendanceScreenState();
}

class _BasicAttendanceScreenState extends State<BasicAttendanceScreen> {
  final List<Map<String, dynamic>> _attendanceRecords = [
    {
      'date': DateTime(2024, 1, 28),
      'event': 'Sunday Service',
      'present': 18,
      'absent': 4,
      'total': 22,
    },
    {
      'date': DateTime(2024, 1, 21),
      'event': 'Sunday Service',
      'present': 20,
      'absent': 2,
      'total': 22,
    },
    {
      'date': DateTime(2024, 1, 14),
      'event': 'Special Practice',
      'present': 15,
      'absent': 7,
      'total': 22,
    },
    {
      'date': DateTime(2024, 1, 7),
      'event': 'Sunday Service',
      'present': 19,
      'absent': 3,
      'total': 22,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              color: AppColors.success,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '87%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              context.tr('attendancePercentage'),
                              style: const TextStyle(
                                color: AppColors.gray600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.people,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '22',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              context.tr('totalMembers'),
                              style: const TextStyle(
                                color: AppColors.gray600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Attendance Records
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Attendance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          return _buildAttendanceCard(
                            _attendanceRecords[index],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final date = record['date'] as DateTime;
    final event = record['event'] as String;
    final present = record['present'] as int;
    final absent = record['absent'] as int;
    final total = record['total'] as int;
    final percentage = ((present / total) * 100).round();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(
                      percentage,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: _getPercentageColor(percentage),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAttendanceStat('Present', present, AppColors.success),
                const SizedBox(width: 16),
                _buildAttendanceStat('Absent', absent, AppColors.error),
                const SizedBox(width: 16),
                _buildAttendanceStat('Total', total, AppColors.gray600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
