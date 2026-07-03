import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _outstandingFees = [];
  Map<String, dynamic> _paymentStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get payments => _payments;
  List<Map<String, dynamic>> get outstandingFees => _outstandingFees;
  Map<String, dynamic> get paymentStats => _paymentStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load payments for a choir
  Future<void> loadChoirPayments({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentStatus? status,
    PaymentType? type,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _payments = await _paymentService.getChoirPayments(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
        type: type,
      );

      // Load payment statistics
      _paymentStats = await _paymentService.getPaymentStatistics(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Load outstanding fees
      _outstandingFees = await _paymentService.getOutstandingFees(choirId);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load choir payments: $e');
      _setLoading(false);
    }
  }

  // Load payments for a specific member
  Future<void> loadMemberPayments({
    required String memberId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      
      _payments = await _paymentService.getMemberPayments(
        memberId: memberId,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load member payments: $e');
      _setLoading(false);
    }
  }

  // Create new payment
  Future<bool> createPayment({
    required String choirId,
    required String memberId,
    required String userId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required String description,
    String? reference,
    String? receivedBy,
    String currency = 'KES',
    String? memberName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final payment = await _paymentService.createPayment(
        choirId: choirId,
        memberId: memberId,
        userId: userId,
        amount: amount,
        type: type,
        method: method,
        description: description,
        reference: reference,
        receivedBy: receivedBy,
        currency: currency,
        memberName: memberName,
      );

      if (payment != null) {
        // Reload payments to get fresh data
        await loadChoirPayments(choirId: choirId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to create payment');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error creating payment: $e');
      _setLoading(false);
      return false;
    }
  }

  // Process payment and update member fees
  Future<bool> processPaymentAndUpdateFees({
    required String choirId,
    required String memberId,
    required String userId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required String description,
    String? reference,
    String? receivedBy,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _paymentService.processPaymentAndUpdateFees(
        choirId: choirId,
        memberId: memberId,
        userId: userId,
        amount: amount,
        type: type,
        method: method,
        description: description,
        reference: reference,
        receivedBy: receivedBy,
      );

      if (success) {
        // Reload all payment related data
        await loadChoirPayments(choirId: choirId);
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to process payment');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error processing payment: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    required String choirId,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _paymentService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        notes: notes,
      );

      if (success) {
        // Update local payment data
        final index = _payments.indexWhere((p) => p['id'] == paymentId);
        if (index != -1) {
          _payments[index]['status'] = status.toString().split('.').last;
          if (notes != null) {
            _payments[index]['notes'] = notes;
          }
        }

        // Reload statistics
        _paymentStats = await _paymentService.getPaymentStatistics(
          choirId: choirId,
        );
        
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update payment status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating payment status: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update member outstanding fees
  Future<bool> updateMemberOutstandingFees({
    required String memberId,
    required double amount,
    required String choirId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _paymentService.updateMemberOutstandingFees(
        memberId: memberId,
        amount: amount,
      );

      if (success) {
        // Update local outstanding fees data
        final index = _outstandingFees.indexWhere((f) => f['id'] == memberId);
        if (index != -1) {
          _outstandingFees[index]['outstanding_fees'] = amount;
          if (amount == 0) {
            _outstandingFees.removeAt(index);
          }
        }
        
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to update outstanding fees');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error updating outstanding fees: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get payment by ID from current list
  Map<String, dynamic>? getPaymentById(String paymentId) {
    try {
      return _payments.firstWhere((payment) => payment['id'] == paymentId);
    } catch (e) {
      return null;
    }
  }

  // Calculate total outstanding fees
  double getTotalOutstandingFees() {
    return _outstandingFees.fold(0.0, (sum, fee) => sum + (fee['outstanding_fees'] ?? 0.0));
  }

  // Get payments by status
  List<Map<String, dynamic>> getPaymentsByStatus(PaymentStatus status) {
    return _payments.where((payment) => 
      payment['status'] == status.toString().split('.').last
    ).toList();
  }

  // Get payments by type
  List<Map<String, dynamic>> getPaymentsByType(PaymentType type) {
    return _payments.where((payment) => 
      payment['type'] == type.toString().split('.').last
    ).toList();
  }

  // Clear data
  void clearData() {
    _payments.clear();
    _outstandingFees.clear();
    _paymentStats.clear();
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