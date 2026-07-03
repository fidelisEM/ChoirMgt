import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/choir_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_utils.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';
import 'add_payment_screen.dart';

class BasicPaymentsScreen extends StatefulWidget {
  const BasicPaymentsScreen({super.key});

  @override
  State<BasicPaymentsScreen> createState() => _BasicPaymentsScreenState();
}

class _BasicPaymentsScreenState extends State<BasicPaymentsScreen> {
  String _selectedCurrency = CurrencyUtils.getDefaultCurrency();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayments();
    });
  }

  Future<void> _loadPayments() async {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    final paymentController = Provider.of<PaymentController>(context, listen: false);
    
    if (choirController.selectedChoir != null) {
      await paymentController.loadChoirPayments(
        choirId: choirController.selectedChoir!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChoirController, PaymentController>(
      builder: (context, choirController, paymentController, child) {
        final selectedChoir = choirController.selectedChoir;
        
        if (selectedChoir == null) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No Choir Selected'),
                  Text('Please select a choir from the Choirs tab first'),
                ],
              ),
            ),
          );
        }

        final payments = paymentController.payments;
        final stats = paymentController.paymentStats;
        
        // Convert all amounts to the selected currency for totals
        final totalRevenue = stats['completed_amount']?.toDouble() ?? 0.0;
        final pendingAmount = stats['pending_amount']?.toDouble() ?? 0.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Financial Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          onTap: () => _showPaymentHistory(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: AppColors.success,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyUtils.formatAmount(totalRevenue, _selectedCurrency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Total Revenue',
                                      style: TextStyle(
                                        color: AppColors.gray600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppColors.gray400,
                                    ),
                                  ],
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
                                  Icons.pending,
                                  color: AppColors.warning,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyUtils.formatAmount(pendingAmount, _selectedCurrency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const Text(
                                  'Pending',
                                  style: TextStyle(
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
                
                // Payments List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            // Header row with title and currency
                            Row(
                              children: [
                                const Text(
                                  'Recent Payments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyUtils.getCurrencyFlag(_selectedCurrency),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedCurrency,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  onSelected: (currency) {
                                    setState(() {
                                      _selectedCurrency = currency;
                                    });
                                  },
                                  itemBuilder: (context) => CurrencyUtils.getSupportedCurrencies()
                                      .map((currency) => PopupMenuItem(
                                            value: currency,
                                            child: Row(
                                              children: [
                                                Text(CurrencyUtils.getCurrencyFlag(currency)),
                                                const SizedBox(width: 8),
                                                Text('$currency - ${CurrencyUtils.getCurrencyName(currency)}'),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.currency_exchange, size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Button row
                            Row(
                              children: [
                                const Spacer(),
                                GradientButton(
                                  text: 'Record Payment',
                                  onPressed: _showRecordPaymentDialog,
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: paymentController.isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : payments.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No payments found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: payments.length,
                                      itemBuilder: (context, index) {
                                        return _buildPaymentCard(payments[index]);
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
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final id = payment['id'] as String;
    final memberData = payment['choir_members'] ?? {};
    final userData = memberData['users'] ?? {};
    final memberName = userData['full_name'] ?? 'Unknown Member';
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final currency = payment['currency'] ?? _selectedCurrency;
    final type = payment['type'] as String;
    final date = DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now();
    final status = payment['status'] as String;
    
    // Convert to selected currency for display
    final displayAmount = CurrencyUtils.convertCurrency(amount, currency, _selectedCurrency);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        memberName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        CurrencyUtils.formatAmount(displayAmount, _selectedCurrency),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPaymentTypeLabel(type),
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        Helpers.formatDate(date),
                        style: const TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• $id',
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.gray500;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      default:
        return Icons.payment;
    }
  }

  void _showRecordPaymentDialog() {
    final choirController = Provider.of<ChoirController>(context, listen: false);
    
    if (choirController.selectedChoir == null) {
      Get.snackbar(
        'Error',
        'Please select a choir first',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    Get.to(() => AddPaymentScreen(choirId: choirController.selectedChoir!.id))
        ?.then((_) => _loadPayments());
  }

  void _showPaymentHistory() {
    final paymentController = Provider.of<PaymentController>(context, listen: false);
    
    // Filter completed payments for history
    final completedPayments = paymentController.payments
        .where((p) => p['status'] == 'completed')
        .toList();
    
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
                  const Icon(Icons.history, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${completedPayments.length} payments',
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.payments, color: Colors.white, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        '${completedPayments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Payments',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white30,
                  ),
                  Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyUtils.formatAmount(
                          completedPayments.fold<double>(0, (sum, p) {
                            final amount = p['amount']?.toDouble() ?? 0.0;
                            final currency = p['currency'] ?? _selectedCurrency;
                            return sum + CurrencyUtils.convertCurrency(
                              amount, currency, _selectedCurrency
                            );
                          }),
                          _selectedCurrency,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Payment list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: completedPayments.length,
                itemBuilder: (context, index) {
                  return _buildHistoryPaymentCard(completedPayments[index], index);
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildHistoryPaymentCard(Map<String, dynamic> payment, int index) {
    final id = payment['id'] as String;
    final memberData = payment['choir_members'] ?? {};
    final userData = memberData['users'] ?? {};
    final memberName = userData['full_name'] ?? 'Unknown Member';
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final currency = payment['currency'] ?? _selectedCurrency;
    final type = payment['type'] as String;
    final date = DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now();
    
    // Convert to selected currency for display
    final displayAmount = CurrencyUtils.convertCurrency(amount, currency, _selectedCurrency);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Payment number
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Payment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.gray800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyUtils.formatAmount(displayAmount, _selectedCurrency),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.category, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      _getPaymentTypeLabel(type),
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Text(
                      Helpers.formatDate(date),
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $id',
                  style: const TextStyle(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
}