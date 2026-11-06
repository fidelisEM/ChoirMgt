import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/choir_controller.dart';
import '../../controllers/member_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../utils/currency_utils.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_widgets.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({
    super.key,
    this.choirId,
    this.memberId,
  });

  final String? choirId;
  final String? memberId;

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedChoirId;
  String? _selectedMemberId;
  PaymentType _selectedType = PaymentType.monthly;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String _selectedCurrency = CurrencyUtils.getDefaultCurrency();
  bool _isLoading = false;
  DateTime _paymentDate = DateTime.now();

  List<ChoirModel> _choirs = [];
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _selectedChoirId = widget.choirId;
    _selectedMemberId = widget.memberId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await _loadChoirs();
    if (_selectedChoirId != null) {
      await _loadMembers(_selectedChoirId!);
    }
  }

  Future<void> _loadChoirs() async {
    try {
      final choirController = Provider.of<ChoirController>(context, listen: false);
      
      await choirController.loadChoirs();
      if (mounted) {
        setState(() {
          _choirs = choirController.choirs;
          if (_choirs.isNotEmpty && _selectedChoirId == null) {
            _selectedChoirId = _choirs.first.id;
          }
        });
        // Use post-frame callback to load members after setState completes
        if (_selectedChoirId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadMembers(_selectedChoirId!);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackbar('${context.tr('payFailedLoadChoirs')}: $e');
      }
    }
  }

  Future<void> _loadMembers(String choirId) async {
    try {
      final memberController = Provider.of<MemberController>(context, listen: false);
      
      await memberController.loadChoirMembers(choirId);
      if (mounted) {
        setState(() {
          _members = memberController.membersWithUserInfo;
        });
      }
    } catch (e) {
      if (mounted) {
        Helpers.showErrorSnackbar('${context.tr('payFailedLoadMembers')}: $e');
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('recordPayment')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildChoirSelection(),
                  const SizedBox(height: 16),
                  _buildMemberSelection(),
                  const SizedBox(height: 16),
                  _buildPaymentTypeSelection(),
                  const SizedBox(height: 16),
                  _buildCurrencySelection(),
                  const SizedBox(height: 16),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSelection(),
                  const SizedBox(height: 16),
                  _buildPaymentDateField(),
                  const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildReferenceField(),
                  const SizedBox(height: 16),
                  _buildNotesField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GlassCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payment,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('payRecordNewPayment'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('payEnterDetailsBelow'),
            style: const TextStyle(
              color: AppColors.gray600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoirSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('paySelectChoirLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedChoirId,
            decoration: InputDecoration(
              labelText: context.tr('payChoirLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.music_note),
            ),
            items: _choirs.map((choir) {
              return DropdownMenuItem<String>(
                value: choir.id,
                child: Text(choir.name),
              );
            }).toList(),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _selectedChoirId = value;
                  _selectedMemberId = null; // Reset member selection
                });
                if (value != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadMembers(value);
                  });
                }
              }
            },
            validator: (value) => Validators.required(value, 'choir'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('paySelectMemberLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedMemberId,
            decoration: InputDecoration(
              labelText: context.tr('payMemberLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
            ),
            items: _members.map((member) {
              final userData = member['users'] ?? {};
              return DropdownMenuItem<String>(
                value: member['id'],
                child: Text('${userData['full_name']} (${member['registration_number']})'),
              );
            }).toList(),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _selectedMemberId = value;
                });
              }
            },
            validator: (value) => Validators.required(value, 'member'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payPaymentTypeLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentType.values.map((type) {
              final isSelected = _selectedType == type;
              return FilterChip(
                selected: isSelected,
                label: Text(_getPaymentTypeLabel(type)),
                onSelected: (selected) {
                  if (mounted) {
                    setState(() {
                      _selectedType = type;
                    });
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('amount'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: InputDecoration(
              labelText: context.tr('amount'),
              prefixText: '${CurrencyUtils.getCurrencySymbol(_selectedCurrency)} ',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.money),
              helperText: '${context.tr('payAmountInPrefix')} ${CurrencyUtils.getCurrencyName(_selectedCurrency)}',
            ),
            validator: (value) => Validators.amount(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payCurrencyLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: InputDecoration(
              labelText: context.tr('paySelectCurrencyLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            items: CurrencyUtils.getSupportedCurrencies().map((currency) {
              return DropdownMenuItem<String>(
                value: currency,
                child: Row(
                  children: [
                    Text(
                      CurrencyUtils.getCurrencyFlag(currency),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${CurrencyUtils.getCurrencySymbol(currency)} ${CurrencyUtils.getCurrencyName(currency)} ($currency)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (mounted) {
                setState(() {
                  _selectedCurrency = value!;
                });
              }
            },
            validator: (value) => Validators.required(value, 'currency'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${context.tr('paySelectedPrefix')}: ${CurrencyUtils.getCurrencySymbol(_selectedCurrency)} ${CurrencyUtils.getCurrencyName(_selectedCurrency)}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payPaymentMethodLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethod.values.map((method) {
              final isSelected = _selectedMethod == method;
              return FilterChip(
                selected: isSelected,
                label: Text(_getPaymentMethodLabel(method)),
                onSelected: (selected) {
                  if (mounted) {
                    setState(() {
                      _selectedMethod = method;
                    });
                  }
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDateField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payPaymentDateLabel'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectPaymentDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.gray600),
                  const SizedBox(width: 12),
                  Text(
                    Helpers.formatDate(_paymentDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: AppColors.gray600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('description'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: context.tr('payPaymentDescriptionLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description),
            ),
            validator: (value) => Validators.required(value, 'description'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payReferenceNumberOptional'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: context.tr('payTransactionReferenceLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.confirmation_number),
              hintText: context.tr('payMpesaHint'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('payNotesOptional'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: context.tr('payAdditionalNotesLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.note),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 64),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
              context.tr('recordPayment'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
      ),
    );
  }

  Future<void> _selectPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) {
      setState(() {
        _paymentDate = date;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChoirId == null || _selectedMemberId == null) {
      Helpers.showErrorSnackbar(context.tr('payPleaseSelectChoirAndMember'));
      return;
    }

    // Resolve translated strings before any async gap so we don't touch
    // BuildContext after an await.
    final authRequiredMessage = context.tr('payAuthenticationRequired');
    final successMessage = context.tr('paySuccessRecorded');
    final failureMessage = context.tr('payFailedRecordPayment');
    final errorPrefix = context.tr('error');

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final paymentController = Provider.of<PaymentController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);
      
      // Get the current authenticated user's ID
      final currentUser = authController.currentUser;
      if (currentUser == null) {
        Helpers.showErrorSnackbar(authRequiredMessage);
        return;
      }
      
      // Get selected member name
      String memberName = 'Selected Member';
      try {
        final selectedMember = _members.firstWhere((member) => member['id'] == _selectedMemberId);
        final userData = selectedMember['users'] ?? {};
        memberName = userData['full_name'] ?? 'Member ${_selectedMemberId!.substring(0, 8)}';
      } catch (e) {
        memberName = 'Member ${_selectedMemberId!.substring(0, 8)}';
      }

      // Attribute the payment to the member's account, not the recorder's.
      String paymentUserId = currentUser.id;
      try {
        final selectedMember = _members.firstWhere((m) => m['id'] == _selectedMemberId);
        paymentUserId = selectedMember['user_id'] ?? selectedMember['users']?['id'] ?? currentUser.id;
      } catch (_) {}

      final success = await paymentController.createPayment(
        choirId: _selectedChoirId!,
        memberId: _selectedMemberId!,
        userId: paymentUserId,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        method: _selectedMethod,
        description: _descriptionController.text,
        reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        receivedBy: 'Current User', // This should be current user's name
        currency: _selectedCurrency,
        memberName: memberName,
      );

      if (success) {
        // Pop first: Get.back() right after a snackbar pops the snackbar
        // route instead of this page, leaving the form open.
        Get.back();
        Helpers.showSuccessSnackbar(successMessage);
      } else {
        Helpers.showErrorSnackbar(failureMessage);
      }
    } catch (e) {
      Helpers.showErrorSnackbar('$errorPrefix: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.registration:
        return context.tr('payRegistrationFee');
      case PaymentType.monthly:
        return context.tr('payMonthlyFee');
      case PaymentType.quarterly:
        return context.tr('payQuarterlyFee');
      case PaymentType.annual:
        return context.tr('payAnnualFee');
      case PaymentType.special:
        return context.tr('paySpecialFee');
      case PaymentType.other:
        return context.tr('payOther');
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return context.tr('payCash');
      case PaymentMethod.bankTransfer:
        return context.tr('payBankTransfer');
      case PaymentMethod.mobilePayment:
        return context.tr('payMobilePayment');
      case PaymentMethod.other:
        return context.tr('payOther');
    }
  }
}