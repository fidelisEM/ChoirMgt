import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/qr_generator.dart';
import '../attendance/attendance_export_screen.dart';
import '../communication/compose_message_screen.dart';
import '../payments/add_payment_screen.dart';
import 'edit_member_screen.dart';

class MemberDetailScreen extends StatelessWidget {

  const MemberDetailScreen({
    super.key,
    required this.member,
  });
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context) {
    final userData = member['users'];
    final name = userData?['full_name'] ?? 'Unknown User';
    final email = userData?['email'] ?? '';
    final phone = userData?['phone_number'] ?? '';
    final regNumber = member['registration_number'] ?? '';
    final status = member['status'] ?? 'active';
    final joinDate = DateTime.tryParse(member['join_date'] ?? '') ?? DateTime.now();
    final outstandingFees = member['outstanding_fees'] ?? 0.0;
    final totalPaid = member['total_paid'] ?? 0.0;
    final totalAttendances = member['total_attendances'] ?? 0;
    final totalAbsences = member['total_absences'] ?? 0;
    final totalLateArrivals = member['total_late_arrivals'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Get.to(() => EditMemberScreen(member: member));
              if (result == true) {
                // Refresh the current screen or reload member data
                Get.snackbar('Success', 'Member profile updated successfully');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: _getStatusColor(status).withAlpha(50),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reg: $regNumber',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Contact Information
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone,
              children: [
                _buildInfoRow('Email', email),
                if (phone.isNotEmpty) _buildInfoRow('Phone', phone),
                _buildInfoRow('Join Date', _formatDate(joinDate)),
              ],
            ),

            const SizedBox(height: 16),

            // Financial Information
            _buildSectionCard(
              title: 'Financial Information',
              icon: Icons.payment,
              children: [
                _buildInfoRow('Outstanding Fees', '\$${outstandingFees.toStringAsFixed(2)}'),
                _buildInfoRow('Total Paid', '\$${totalPaid.toStringAsFixed(2)}'),
                _buildInfoRow('Balance', '\$${(totalPaid - outstandingFees).toStringAsFixed(2)}'),
              ],
            ),

            const SizedBox(height: 16),

            // Attendance Statistics
            _buildSectionCard(
              title: 'Attendance Statistics',
              icon: Icons.check_circle,
              children: [
                _buildInfoRow('Total Attendances', totalAttendances.toString()),
                _buildInfoRow('Total Absences', totalAbsences.toString()),
                _buildInfoRow('Late Arrivals', totalLateArrivals.toString()),
                _buildInfoRow(
                  'Attendance Rate',
                  '${_calculateAttendanceRate(totalAttendances, totalAbsences).toStringAsFixed(1)}%',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildActionButton(
                          label: 'Record Payment',
                          icon: Icons.payment,
                          color: Colors.green,
                          onTap: () => Get.to(() => AddPaymentScreen(
                            choirId: member['choir_id'],
                            memberId: member['id'],
                          )),
                        ),
                        _buildActionButton(
                          label: 'Export Attendance',
                          icon: Icons.file_download,
                          color: Colors.blue,
                          onTap: () => Get.to(() => const AttendanceExportScreen()),
                        ),
                        _buildActionButton(
                          label: 'Send Message',
                          icon: Icons.message,
                          color: Colors.purple,
                          onTap: () => Get.to(() => ComposeMessageScreen(
                            subject: 'Message to $name',
                          )),
                        ),
                        _buildActionButton(
                          label: 'View History',
                          icon: Icons.history,
                          color: Colors.orange,
                          onTap: () => _showMemberHistory(context, member),
                        ),
                        _buildActionButton(
                          label: 'Show QR Code',
                          icon: Icons.qr_code,
                          color: Colors.indigo,
                          onTap: () => _showQRCode(context, name, regNumber, member['choir_id'] ?? ''),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // QR Code Section
            const SizedBox(height: 16),
            QRGenerator.buildMemberQRCard(
              fullName: name,
              registrationNumber: regNumber,
              choirId: member['choir_id'] ?? '',
              qrSize: 150,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context, String fullName, String regNumber, String choirId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Member QR Code'),
        content: SizedBox(
          width: 250,
          child: QRGenerator.buildMemberQRCard(
            fullName: fullName,
            registrationNumber: regNumber,
            choirId: choirId,
            qrSize: 200,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateAttendanceRate(int attendances, int absences) {
    final total = attendances + absences;
    return total > 0 ? (attendances / total) * 100 : 0.0;
  }

  void _showMemberHistory(BuildContext context, Map<String, dynamic> member) {
    final userData = member['users'];
    final name = userData?['full_name'] ?? 'Unknown User';
    
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  Text(
                    '$name\'s History',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            
            // History tabs
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      labelColor: Color(0xFF6366F1),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF6366F1),
                      tabs: [
                        Tab(text: 'Attendance'),
                        Tab(text: 'Payments'),
                        Tab(text: 'Activities'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAttendanceHistory(member),
                          _buildPaymentHistory(member),
                          _buildActivityHistory(member),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildAttendanceHistory(Map<String, dynamic> member) {
    // Mock attendance data - in real app this would come from the database
    final attendanceHistory = [
      {'date': '2024-01-28', 'status': 'Present', 'session': 'Sunday Service'},
      {'date': '2024-01-25', 'status': 'Late', 'session': 'Practice Session'},
      {'date': '2024-01-21', 'status': 'Present', 'session': 'Sunday Service'},
      {'date': '2024-01-18', 'status': 'Absent', 'session': 'Practice Session'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceHistory.length,
      itemBuilder: (context, index) {
        final record = attendanceHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getAttendanceStatusColor(record['status']!),
              child: Icon(
                _getAttendanceStatusIcon(record['status']!),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(record['session']!),
            subtitle: Text(record['date']!),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAttendanceStatusColor(record['status']!).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record['status']!,
                style: TextStyle(
                  color: _getAttendanceStatusColor(record['status']!),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentHistory(Map<String, dynamic> member) {
    // Mock payment data
    final paymentHistory = [
      {'date': '2024-01-28', 'amount': '\$50.00', 'type': 'Monthly Dues', 'status': 'Completed'},
      {'date': '2024-01-15', 'amount': '\$25.00', 'type': 'Event Fee', 'status': 'Completed'},
      {'date': '2024-01-01', 'amount': '\$50.00', 'type': 'Monthly Dues', 'status': 'Completed'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.payment, color: Colors.white, size: 20),
            ),
            title: Text(payment['type']!),
            subtitle: Text(payment['date']!),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  payment['amount']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                Text(
                  payment['status']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityHistory(Map<String, dynamic> member) {
    // Mock activity data
    final activityHistory = [
      {'date': '2024-01-28', 'activity': 'Joined choir', 'description': 'Welcome to the choir!'},
      {'date': '2024-01-25', 'activity': 'Status updated', 'description': 'Changed to Active'},
      {'date': '2024-01-20', 'activity': 'Profile updated', 'description': 'Contact information updated'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activityHistory.length,
      itemBuilder: (context, index) {
        final activity = activityHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF6366F1),
              child: Icon(Icons.event, color: Colors.white, size: 20),
            ),
            title: Text(activity['activity']!),
            subtitle: Text('${activity['date']!}\n${activity['description']!}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Color _getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check;
      case 'late':
        return Icons.schedule;
      case 'absent':
        return Icons.close;
      default:
        return Icons.help;
    }
  }
}