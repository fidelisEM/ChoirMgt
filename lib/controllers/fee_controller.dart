import 'package:flutter/foundation.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';

class FeeController extends ChangeNotifier {
  final FeeService _feeService = FeeService();

  List<FeeDefinitionModel> _feeDefinitions = [];
  List<MemberFeeModel> _memberFees = [];
  List<FeePaymentModel> _payments = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<FeeDefinitionModel> get feeDefinitions => _feeDefinitions;
  List<MemberFeeModel> get memberFees => _memberFees;
  List<FeePaymentModel> get payments => _payments;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fee Definition Management
  Future<void> loadChoirFeeDefinitions(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      _feeDefinitions = await _feeService.getChoirFeeDefinitions(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading fee definitions: $e');
      _setLoading(false);
    }
  }

  Future<bool> createFeeDefinition({
    required String choirId,
    required String name,
    required String description,
    required double amount,
    required FeeType type,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final feeDefinition = await _feeService.createFeeDefinition(
        choirId: choirId,
        name: name,
        description: description,
        amount: amount,
        type: type,
        startDate: startDate,
        endDate: endDate,
        category: category,
        metadata: metadata,
      );

      _feeDefinitions.add(feeDefinition);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error creating fee definition: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateFeeDefinition(
    String feeId, {
    String? name,
    String? description,
    double? amount,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final updatedFee = await _feeService.updateFeeDefinition(
        feeId,
        name: name,
        description: description,
        amount: amount,
        isActive: isActive,
        startDate: startDate,
        endDate: endDate,
        category: category,
        metadata: metadata,
      );

      if (updatedFee != null) {
        final index = _feeDefinitions.indexWhere((fee) => fee.id == feeId);
        if (index != -1) {
          _feeDefinitions[index] = updatedFee;
        }
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update fee definition');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating fee definition: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteFeeDefinition(String feeId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _feeService.deleteFeeDefinition(feeId);

      if (success) {
        _feeDefinitions.removeWhere((fee) => fee.id == feeId);
        _memberFees.removeWhere((fee) => fee.feeDefinitionId == feeId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to delete fee definition');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error deleting fee definition: $e');
      _setLoading(false);
      return false;
    }
  }

  // Member Fee Management
  Future<void> loadMemberFees(String memberId) async {
    try {
      _setLoading(true);
      _clearError();

      _memberFees = await _feeService.getMemberFees(memberId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading member fees: $e');
      _setLoading(false);
    }
  }

  Future<void> loadChoirFees(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      _memberFees = await _feeService.getChoirFees(choirId);
      _statistics = await _feeService.getChoirFeeStatistics(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading choir fees: $e');
      _setLoading(false);
    }
  }

  Future<void> loadOverdueFees(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      _memberFees = await _feeService.getOverdueFees(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading overdue fees: $e');
      _setLoading(false);
    }
  }

  // Payment Management
  Future<bool> recordPayment({
    required String memberFeeId,
    required double amount,
    required String paymentMethod,
    required String recordedBy,
    String? reference,
    String? notes,
    DateTime? paidAt,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final payment = await _feeService.recordPayment(
        memberFeeId: memberFeeId,
        amount: amount,
        paymentMethod: paymentMethod,
        recordedBy: recordedBy,
        reference: reference,
        notes: notes,
        paidAt: paidAt,
      );

      _payments.add(payment);

      // Update the corresponding member fee
      final feeIndex = _memberFees.indexWhere((fee) => fee.id == memberFeeId);
      if (feeIndex != -1) {
        final updatedFee = _memberFees[feeIndex].copyWith(
          amountPaid: _memberFees[feeIndex].amountPaid + amount,
          paidAt: _memberFees[feeIndex].isPaid
              ? (paidAt ?? DateTime.now())
              : null,
        );
        _memberFees[feeIndex] = updatedFee;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error recording payment: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadMemberPayments(String memberId) async {
    try {
      _setLoading(true);
      _clearError();

      _payments = await _feeService.getMemberPayments(memberId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading member payments: $e');
      _setLoading(false);
    }
  }

  Future<void> loadChoirPayments(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      _payments = await _feeService.getChoirPayments(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error loading choir payments: $e');
      _setLoading(false);
    }
  }

  // Automated Operations
  Future<void> generateRecurringFees(String choirId) async {
    try {
      _setLoading(true);
      _clearError();

      await _feeService.generateRecurringFees(choirId);

      // Reload fees and statistics
      await loadChoirFees(choirId);
      _setLoading(false);
    } catch (e) {
      _setError('Error generating recurring fees: $e');
      _setLoading(false);
    }
  }

  // Utility methods
  List<MemberFeeModel> getMemberOutstandingFees(String memberId) {
    return _memberFees
        .where((fee) => fee.memberId == memberId && fee.outstandingAmount > 0)
        .toList();
  }

  List<MemberFeeModel> getOverdueFees() {
    return _memberFees.where((fee) => fee.isOverdue).toList();
  }

  List<MemberFeeModel> getFeesByStatus(FeeStatus status) {
    return _memberFees.where((fee) => fee.status == status).toList();
  }

  List<MemberFeeModel> getFeesByType(String feeDefinitionId) {
    return _memberFees
        .where((fee) => fee.feeDefinitionId == feeDefinitionId)
        .toList();
  }

  double getTotalOutstanding(String? memberId) {
    final relevantFees = memberId != null
        ? _memberFees.where((fee) => fee.memberId == memberId)
        : _memberFees;

    return relevantFees.fold<double>(
      0,
      (sum, fee) => sum + fee.outstandingAmount,
    );
  }

  double getTotalPaid(
    String? memberId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    var relevantPayments = memberId != null
        ? _payments.where((payment) => payment.memberId == memberId)
        : _payments;

    if (fromDate != null) {
      relevantPayments = relevantPayments.where(
        (payment) =>
            payment.paidAt.isAfter(fromDate) ||
            payment.paidAt.isAtSameMomentAs(fromDate),
      );
    }

    if (toDate != null) {
      relevantPayments = relevantPayments.where(
        (payment) =>
            payment.paidAt.isBefore(toDate) ||
            payment.paidAt.isAtSameMomentAs(toDate),
      );
    }

    return relevantPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );
  }

  FeeDefinitionModel? getFeeDefinitionById(String feeDefinitionId) {
    try {
      return _feeDefinitions.firstWhere((def) => def.id == feeDefinitionId);
    } catch (e) {
      return null;
    }
  }

  // Clear and reset
  void clearData() {
    _feeDefinitions.clear();
    _memberFees.clear();
    _payments.clear();
    _statistics.clear();
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
