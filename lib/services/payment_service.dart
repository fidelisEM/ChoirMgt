import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/logger.dart';

class PaymentService {
  factory PaymentService() => _instance;
  PaymentService._internal();
  static final PaymentService _instance = PaymentService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  String _enumName(Object value) => value.toString().split('.').last;

  // Create payment record
  Future<PaymentModel?> createPayment({
    required String choirId,
    required String memberId,
    required String userId,
    required double amount,
    required PaymentType type,
    required PaymentMethod method,
    required String description,
    String? reference,
    String? receivedBy,
    String currency = 'TZS',
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .insert({
            'choir_id': choirId,
            'member_id': memberId,
            'user_id': userId,
            'amount': amount,
            'type': _enumName(type),
            'method': _enumName(method),
            'description': description,
            'reference': reference,
            'received_by': receivedBy,
            'currency': currency,
            'status': _enumName(PaymentStatus.completed),
          })
          .select()
          .single();

      final payment = PaymentModel.fromJson(response);
      Logger.info('Payment created: ${payment.id} for choir $choirId');
      return payment;
    } catch (e) {
      Logger.error('Error creating payment', e);
      return null;
    }
  }

  // Get payments for a choir, newest first
  Future<List<Map<String, dynamic>>> getChoirPayments({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentStatus? status,
    PaymentType? type,
  }) async {
    try {
      var query = _supabase
          .from('payments')
          .select('''
            *,
            choir_members!payments_member_id_fkey (
              registration_number,
              users!choir_members_user_id_fkey (
                id,
                full_name,
                email
              )
            )
          ''')
          .eq('choir_id', choirId);

      if (fromDate != null) {
        query = query.gte('payment_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('payment_date', toDate.toIso8601String());
      }
      if (status != null) {
        query = query.eq('status', _enumName(status));
      }
      if (type != null) {
        query = query.eq('type', _enumName(type));
      }

      final response = await query.order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching choir payments', e);
      return [];
    }
  }

  // Get payments for a specific member
  Future<List<Map<String, dynamic>>> getMemberPayments({
    required String memberId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('payments')
          .select('''
            *,
            choirs!payments_choir_id_fkey (
              name
            )
          ''')
          .eq('member_id', memberId);

      if (fromDate != null) {
        query = query.gte('payment_date', fromDate.toIso8601String());
      }

      if (toDate != null) {
        query = query.lte('payment_date', toDate.toIso8601String());
      }

      final response = await query.order('payment_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching member payments', e);
      return [];
    }
  }

  // Delete a payment. RLS silently deletes zero rows for users without
  // permission, so success means a row actually came back.
  Future<bool> deletePayment(String paymentId) async {
    try {
      final deleted = await _supabase
          .from('payments')
          .delete()
          .eq('id', paymentId)
          .select('id');
      return deleted.isNotEmpty;
    } catch (e) {
      Logger.error('Error deleting payment', e);
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _supabase.from('payments').update(updates).eq('id', paymentId);

      return true;
    } catch (e) {
      Logger.error('Error updating payment status', e);
      return false;
    }
  }

  // Get payment statistics for a choir
  Future<Map<String, dynamic>> getPaymentStatistics({
    required String choirId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // Get all payments in the date range
      final payments = await getChoirPayments(
        choirId: choirId,
        fromDate: fromDate,
        toDate: toDate,
      );

      double totalAmount = 0.0;
      double completedAmount = 0.0;
      double pendingAmount = 0.0;
      double refundedAmount = 0.0;

      final int totalPayments = payments.length;
      int completedPayments = 0;
      int pendingPayments = 0;
      int refundedPayments = 0;

      final Map<String, double> typeBreakdown = {};
      final Map<String, double> methodBreakdown = {};

      for (final payment in payments) {
        final amount = payment['amount']?.toDouble() ?? 0.0;
        final status = payment['status'] as String? ?? 'completed';
        final type = payment['type'] as String? ?? 'monthly';
        final method = payment['method'] as String? ?? 'cash';

        totalAmount += amount;

        switch (status) {
          case 'completed':
            completedAmount += amount;
            completedPayments++;
            break;
          case 'pending':
            pendingAmount += amount;
            pendingPayments++;
            break;
          case 'refunded':
            refundedAmount += amount;
            refundedPayments++;
            break;
        }

        // Type breakdown
        typeBreakdown[type] = (typeBreakdown[type] ?? 0.0) + amount;

        // Method breakdown
        methodBreakdown[method] = (methodBreakdown[method] ?? 0.0) + amount;
      }

      return {
        'total_amount': totalAmount,
        'completed_amount': completedAmount,
        'pending_amount': pendingAmount,
        'refunded_amount': refundedAmount,
        'total_payments': totalPayments,
        'completed_payments': completedPayments,
        'pending_payments': pendingPayments,
        'refunded_payments': refundedPayments,
        'type_breakdown': typeBreakdown,
        'method_breakdown': methodBreakdown,
      };
    } catch (e) {
      Logger.error('Error getting payment statistics', e);
      return {};
    }
  }

  // Get outstanding fees for choir members
  Future<List<Map<String, dynamic>>> getOutstandingFees(String choirId) async {
    try {
      final response = await _supabase
          .from('choir_members')
          .select('''
            id,
            outstanding_fees,
            registration_number,
            users!choir_members_user_id_fkey (
              id,
              full_name,
              email
            )
          ''')
          .eq('choir_id', choirId)
          .gt('outstanding_fees', 0)
          .order('outstanding_fees', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Logger.error('Error fetching outstanding fees', e);
      return [];
    }
  }

  // Update member outstanding fees
  Future<bool> updateMemberOutstandingFees({
    required String memberId,
    required double amount,
  }) async {
    try {
      await _supabase
          .from('choir_members')
          .update({'outstanding_fees': amount})
          .eq('id', memberId);

      return true;
    } catch (e) {
      Logger.error('Error updating outstanding fees', e);
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
      // Create payment record
      final payment = await createPayment(
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

      if (payment == null) return false;

      // Update member outstanding fees
      final memberResponse = await _supabase
          .from('choir_members')
          .select('outstanding_fees')
          .eq('id', memberId)
          .single();

      final currentFees = memberResponse['outstanding_fees'].toDouble();
      final newFees = currentFees - amount;

      await updateMemberOutstandingFees(
        memberId: memberId,
        amount: newFees > 0 ? newFees : 0,
      );

      return true;
    } catch (e) {
      Logger.error('Error processing payment', e);
      return false;
    }
  }
}
