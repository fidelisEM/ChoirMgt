import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/choir_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/currency_utils.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_widgets.dart';
import '../choirs/choir_list_screen.dart';
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
      _initializeAndLoad();
    });
  }

  Future<void> _initializeAndLoad() async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    final authController = Provider.of<AuthController>(context, listen: false);

    // Load choirs for selection if not already loaded, so this screen
    // doesn't force the user out to the Choirs tab just to pick one.
    if (choirController.choirs.isEmpty) {
      await choirController.loadChoirs(userId: authController.currentUser?.id);
    }

    await _loadPayments();
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

  Future<void> _selectChoir(ChoirModel choir) async {
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );
    await choirController.selectChoir(choir);
    await _loadPayments();
  }

  void _showChoirSwitcher(ChoirController choirController) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        // The Container above paints its own background color, which
        // hides ListTile's ink splashes unless the ListTiles get their
        // own Material ancestor to paint against.
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  context.tr('paySwitchChoirTitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: choirController.choirs.map((choir) {
                    final isSelected =
                        choir.id == choirController.selectedChoir?.id;
                    return ListTile(
                      leading: Icon(
                        Icons.group,
                        color: isSelected ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(choir.name),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        Get.back();
                        if (!isSelected) _selectChoir(choir);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.list),
                title: Text(context.tr('payBrowseAllChoirs')),
                onTap: () {
                  Get.back();
                  Get.to(() => const ChoirListScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
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
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.tr('paySelectChoirHeadline'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('paySelectChoirSubtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    if (choirController.choirs.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: DropdownButtonFormField<ChoirModel>(
                          decoration: InputDecoration(
                            labelText: context.tr('paySelectChoirLabel'),
                            prefixIcon: const Icon(Icons.group),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          hint: Text(context.tr('payChooseChoirHint')),
                          isExpanded: true,
                          items: choirController.choirs.map((choir) {
                            return DropdownMenuItem<ChoirModel>(
                              value: choir,
                              child: Text(
                                choir.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (choir) {
                            if (choir != null) _selectChoir(choir);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('or'),
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ] else if (choirController.isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => Get.to(() => const ChoirListScreen()),
                      icon: const Icon(Icons.list),
                      label: Text(context.tr('payBrowseAllChoirs')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final payments = paymentController.payments;

        // Convert each payment into the selected currency before summing, so
        // the totals follow the currency picker like the list does.
        double sumByStatus(String status) => payments
            .where((p) => p['status'] == status)
            .fold<double>(0, (sum, p) {
              final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final currency = (p['currency'] ?? _selectedCurrency) as String;
              return sum +
                  CurrencyUtils.convertCurrency(
                    amount,
                    currency,
                    _selectedCurrency,
                  );
            });
        final totalRevenue = sumByStatus('completed');
        final pendingAmount = sumByStatus('pending');
        final horizontalPadding = MediaQuery.of(context).size.width < 600
            ? 16.0
            : 32.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Choir header + switcher -- payments always belong to a
                // choir, but there was previously no way to see which one
                // was active or change it without leaving this screen.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedChoir.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showChoirSwitcher(choirController),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: Text(context.tr('paySwitch')),
                      ),
                    ],
                  ),
                ),

                // Financial Summary
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
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
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    CurrencyUtils.formatAmount(
                                      totalRevenue,
                                      _selectedCurrency,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.tr('payTotalRevenue'),
                                      style: const TextStyle(
                                        color: AppColors.gray600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
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
                          onTap: () => _showPaymentHistory(status: 'pending'),
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
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    CurrencyUtils.formatAmount(
                                      pendingAmount,
                                      _selectedCurrency,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      context.tr('pending'),
                                      style: const TextStyle(
                                        color: AppColors.gray600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
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
                    ],
                  ),
                ),

                // Payments List
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            // Header row with title and currency
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr('payRecentPayments'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gray800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyUtils.getCurrencyFlag(
                                          _selectedCurrency,
                                        ),
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
                                  itemBuilder: (context) =>
                                      CurrencyUtils.getSupportedCurrencies()
                                          .map(
                                            (currency) => PopupMenuItem(
                                              value: currency,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    CurrencyUtils.getCurrencyFlag(
                                                      currency,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '$currency - ${CurrencyUtils.getCurrencyName(currency)}',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.currency_exchange,
                                      size: 16,
                                    ),
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
                                  text: context.tr('recordPayment'),
                                  onPressed: _showRecordPaymentDialog,
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: paymentController.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : payments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.payment,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.tr('payNoPaymentsFound'),
                                        style: const TextStyle(
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
    final memberName =
        userData['full_name'] ?? context.tr('payUnknownMemberFallback');
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final currency = payment['currency'] ?? _selectedCurrency;
    final type = payment['type'] as String;
    final date =
        DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now();
    final status = payment['status'] as String;

    // Convert to selected currency for display
    final displayAmount = CurrencyUtils.convertCurrency(
      amount,
      currency,
      _selectedCurrency,
    );

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
                      Expanded(
                        child: Text(
                          memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyUtils.formatAmount(
                          displayAmount,
                          _selectedCurrency,
                        ),
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
                      Expanded(
                        child: Text(
                          '${Helpers.formatDate(date)} • ${id.length > 8 ? id.substring(0, 8) : id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.gray500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
            if (_canManagePayments())
              IconButton(
                tooltip: context.tr('payDeletePayment'),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _confirmDeletePayment(id),
              ),
          ],
        ),
      ),
    );
  }

  bool _canManagePayments() {
    final authController = Provider.of<AuthController>(context, listen: false);
    final choir = Provider.of<ChoirController>(
      context,
      listen: false,
    ).selectedChoir;
    final userId = authController.currentUser?.id;
    return authController.isAdmin ||
        (userId != null &&
            (choir?.leaderId == userId || choir?.adminId == userId));
  }

  Future<void> _confirmDeletePayment(String paymentId) async {
    final choirId = Provider.of<ChoirController>(
      context,
      listen: false,
    ).selectedChoir?.id;
    if (choirId == null) return;
    final paymentController = Provider.of<PaymentController>(
      context,
      listen: false,
    );
    final deletedMsg = context.tr('payPaymentDeleted');
    final failedMsg = context.tr('payFailedDeletePayment');

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(context.tr('payDeletePayment')),
        content: Text(context.tr('payDeletePaymentConfirm')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await paymentController.deletePayment(
      paymentId: paymentId,
      choirId: choirId,
    );
    if (success) {
      Helpers.showSuccessSnackbar(deletedMsg);
    } else {
      Helpers.showErrorSnackbar(failedMsg);
    }
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
    final choirController = Provider.of<ChoirController>(
      context,
      listen: false,
    );

    if (choirController.selectedChoir == null) {
      Get.snackbar(
        context.tr('error'),
        context.tr('payPleaseSelectChoirFirst'),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Get.to(
      () => AddPaymentScreen(choirId: choirController.selectedChoir!.id),
    )?.then((_) => _loadPayments());
  }

  void _showPaymentHistory({String status = 'completed'}) {
    final paymentController = Provider.of<PaymentController>(
      context,
      listen: false,
    );

    // Payments with the requested status (completed history, or pending)
    final completedPayments = paymentController.payments
        .where((p) => p['status'] == status)
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
                  Text(
                    status == 'pending'
                        ? context.tr('pending')
                        : context.tr('paymentHistory'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${completedPayments.length} ${context.tr('payPaymentsCountSuffix')}',
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
                      Text(
                        context.tr('payTotalPaymentsLabel'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.white30),
                  Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyUtils.formatAmount(
                          completedPayments.fold<double>(0, (sum, p) {
                            final amount = p['amount']?.toDouble() ?? 0.0;
                            final currency = p['currency'] ?? _selectedCurrency;
                            return sum +
                                CurrencyUtils.convertCurrency(
                                  amount,
                                  currency,
                                  _selectedCurrency,
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
                      Text(
                        context.tr('payTotalAmountLabel'),
                        style: const TextStyle(
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
                  return _buildHistoryPaymentCard(
                    completedPayments[index],
                    index,
                  );
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
    final memberName =
        userData['full_name'] ?? context.tr('payUnknownMemberFallback');
    final amount = payment['amount']?.toDouble() ?? 0.0;
    final currency = payment['currency'] ?? _selectedCurrency;
    final type = payment['type'] as String;
    final date =
        DateTime.tryParse(payment['payment_date'] ?? '') ?? DateTime.now();

    // Convert to selected currency for display
    final displayAmount = CurrencyUtils.convertCurrency(
      amount,
      currency,
      _selectedCurrency,
    );

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
                    Expanded(
                      child: Text(
                        memberName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyUtils.formatAmount(
                        displayAmount,
                        _selectedCurrency,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    const Icon(
                      Icons.category,
                      size: 14,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getPaymentTypeLabel(type),
                      style: const TextStyle(
                        color: AppColors.gray600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.gray500,
                    ),
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
                  '${context.tr('payIdPrefix')}: $id',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        return context.tr('payRegistrationFee');
      case 'monthly':
        return context.tr('payMonthlyFee');
      case 'quarterly':
        return context.tr('payQuarterlyFee');
      case 'annual':
        return context.tr('payAnnualFee');
      case 'special':
        return context.tr('paySpecialFee');
      case 'other':
        return context.tr('payOther');
      default:
        return type;
    }
  }
}
