import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../utils/currency_utils.dart';
import '../../utils/helpers.dart';
import 'add_payment_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final paymentController = Provider.of<PaymentController>(
      context,
      listen: false,
    );

    if (choirController.selectedChoir != null) {
      await paymentController.loadChoirPayments(
        choirId: choirController.selectedChoir!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer3<AuthController, ChoirController, PaymentController>(
        builder: (context, authController, choirController, paymentController, child) {
          final selectedChoir = choirController.selectedChoir;

          if (selectedChoir == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Choir Selected'),
                  Text('Please select a choir from the Choirs tab first'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Management',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Manage payments for ${selectedChoir.name}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Quick Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total Collected',
                                CurrencyUtils.formatKSH(
                                  paymentController
                                          .paymentStats['completed_amount'] ??
                                      0,
                                ),
                                Icons.payments,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'Outstanding',
                                CurrencyUtils.formatKSH(
                                  paymentController.getTotalOutstandingFees(),
                                ),
                                Icons.pending,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatCard(
                                'This Month',
                                CurrencyUtils.formatKSH(
                                  _getThisMonthPayments(
                                    paymentController.payments,
                                  ),
                                ),
                                Icons.today,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                if (authController.isChoirLeader) ...[
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _recordPayment(),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'Record Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _viewOutstandingFees(),
                          icon: const Icon(Icons.list, size: 20),
                          label: const Text(
                            'View Outstanding Fees',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Recent Payments Section
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search field for payments
                if (paymentController.payments.isNotEmpty &&
                    !paymentController.isLoading) ...[
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search payments by member name or type...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payments List
                if (paymentController.isLoading)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (paymentController.payments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No payments recorded yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            authController.isChoirLeader
                                ? 'Start by recording your first payment'
                                : 'Payment history will appear here',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (authController.isChoirLeader) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _recordPayment(selectedChoir.id),
                                icon: const Icon(Icons.add, size: 20),
                                label: const Text(
                                  'Record First Payment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 28,
                                  ),
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  _buildFilteredPaymentsList(paymentController),

                if (paymentController.payments.isNotEmpty &&
                    paymentController.payments.length > 10)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextButton(
                        onPressed: _viewAllPayments,
                        child: Text(
                          'View All Payments (${paymentController.payments.length})',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _recordPayment([String? choirId]) {
    Get.to(
      () => AddPaymentScreen(choirId: choirId),
    )?.then((_) => _loadPayments());
  }

  void _viewOutstandingFees() {
    final paymentController = Provider.of<PaymentController>(
      context,
      listen: false,
    );

    if (paymentController.outstandingFees.isEmpty) {
      Get.snackbar(
        'Outstanding Fees',
        'No outstanding fees found',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.pending, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Text(
                    'Outstanding Fees',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${CurrencyUtils.formatKSH(paymentController.getTotalOutstandingFees())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: paymentController.outstandingFees.length,
                itemBuilder: (context, index) {
                  final fee = paymentController.outstandingFees[index];
                  final userData = fee['users'] ?? {};
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          userData['full_name']?.substring(0, 1) ?? 'U',
                        ),
                      ),
                      title: Text(userData['full_name'] ?? 'Unknown'),
                      subtitle: Text('Reg: ${fee['registration_number']}'),
                      trailing: Text(
                        CurrencyUtils.formatKSH(fee['outstanding_fees'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      onTap: () {
                        Get.back();
                        _recordPayment();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _viewAllPayments() {
    // TODO: Navigate to full payments screen
    Get.snackbar(
      'All Payments',
      'Full payment history view coming soon!',
      snackPosition: SnackPosition.TOP,
    );
  }

  Widget _buildFilteredPaymentsList(PaymentController paymentController) {
    final filteredPayments = paymentController.payments.where((payment) {
      if (_searchController.text.isEmpty) return true;

      final memberData = payment['choir_members'] ?? {};
      final userData = memberData['users'] ?? {};
      final memberName = userData['full_name']?.toString().toLowerCase() ?? '';
      final type = payment['type']?.toString().toLowerCase() ?? '';
      final status = payment['status']?.toString().toLowerCase() ?? '';

      final query = _searchController.text.toLowerCase();
      return memberName.contains(query) ||
          type.contains(query) ||
          status.contains(query) ||
          _getPaymentTypeLabel(type).toLowerCase().contains(query);
    }).toList();

    if (filteredPayments.isEmpty && _searchController.text.isNotEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No matching payments found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final paymentsToShow = filteredPayments.take(10).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentsToShow.length,
      itemBuilder: (context, index) {
        final payment = paymentsToShow[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final memberData = payment['choir_members'] ?? {};
    final userData = memberData['users'] ?? {};
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final status = payment['status'] ?? 'unknown';
    final type = payment['type'] ?? 'unknown';
    final paymentDate =
        DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withAlpha(50),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 20,
          ),
        ),
        title: Text(
          userData['full_name'] ?? 'Unknown Member',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getPaymentTypeLabel(type)),
            Text(
              Helpers.formatDate(paymentDate),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              CurrencyUtils.formatKSH(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'refunded':
        return Icons.money_off;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'registration':
        return 'Registration Fee';
      case 'monthly':
        return 'Monthly Fee';
      case 'quarterly':
        return 'Quarterly Fee';
      case 'annual':
        return 'Annual Fee';
      case 'special':
        return 'Special Fee';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  double _getThisMonthPayments(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return payments
        .where((payment) {
          final paymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
          return paymentDate != null &&
              paymentDate.isAfter(thisMonth) &&
              payment['status'] == 'completed';
        })
        .fold(
          0.0,
          (sum, payment) => sum + (payment['amount']?.toDouble() ?? 0.0),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
